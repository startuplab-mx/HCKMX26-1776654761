import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_control_page.dart';

class SettingsPage extends StatefulWidget {
  final String currentUserEmail;
  final VoidCallback onToggleTheme;

  SettingsPage({required this.currentUserEmail, required this.onToggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool parentalControl = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool hasControls = false;
  int? currentUserAge;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserAge();
    _loadParentalControl();
    _checkControls();
  }

  Future<void> _loadUserAge() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.currentUserEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      setState(() {
        currentUserAge = userSnapshot.docs.first['edad'] ?? 0;
      });
    }
  }

  Future<void> _loadParentalControl() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc(widget.currentUserEmail)
        .get();

    if (doc.exists) {
      setState(() {
        parentalControl = doc['parentalControl'] ?? false;
      });
    }
  }

  Future<void> _saveParentalControl(bool value) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc(widget.currentUserEmail)
        .set({'parentalControl': value}, SetOptions(merge: true));
  }

  Future<void> _checkControls() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('control')
        .where('correo_tutor', isEqualTo: widget.currentUserEmail)
        .get();

    setState(() {
      hasControls = snapshot.docs.isNotEmpty;
    });
  }

  Future<void> _logout() async {
    // Solo cerrar sesión — el StreamBuilder en main.dart redirige automáticamente
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query)
        .get();

    // Filtrar menores de edad — acepta tanto int como String guardado en Firestore
    final results = snapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          final edadRaw = data['edad'];
          final edad = edadRaw is int
              ? edadRaw
              : int.tryParse(edadRaw?.toString() ?? '') ?? 99;
          return edad < 18;
        })
        .toList();

    List<Map<String, dynamic>> filteredResults = [];

    for (var user in results) {
      final correoMenor = user['email'];

      // Verificar si ya existe un control entre tutor y menor
      final controlSnapshot = await FirebaseFirestore.instance
          .collection('control')
          .where('correo_tutor', isEqualTo: widget.currentUserEmail)
          .where('correo_menor', isEqualTo: correoMenor)
          .get();

      if (controlSnapshot.docs.isNotEmpty) {
        // Ya existe control, mostrar aviso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ya existe un control con $correoMenor"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Solo agregar si no existe control
        filteredResults.add(user.cast<String, dynamic>());
      }
    }

    setState(() {
      searchResults = filteredResults;
      isSearching = false;
    });

    if (filteredResults.isEmpty && snapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("El usuario no cumple los requisitos (menor de 18 años) o ya está vinculado."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se encontró ningún usuario con ese correo."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Generar y guardar código en Firestore, luego mostrar modal
  Future<void> _requestCode(String targetEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debes iniciar sesión para vincular cuentas")),
      );
      return;
    }

    // Generar código de 6 dígitos
    final code =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // ── Paso 1: Guardar el código (crítico) ──────────────────────────
    try {
      await FirebaseFirestore.instance.collection('codes').add({
        'code': code,
        'targetEmail': targetEmail,
        'owner': widget.currentUserEmail,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al generar el código. Verifica las reglas de Firestore."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // Solo salir si no se pudo guardar el código
    }

    // ── Paso 2: Enviar código por chat (no crítico, fallo silencioso) ──
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final targetUid = userDoc.docs.first.id;

        final chatsQuery = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .get();

        DocumentReference? chatRef;
        for (var doc in chatsQuery.docs) {
          final participants = List<String>.from(doc['participants']);
          if (participants.contains(targetUid)) {
            chatRef = doc.reference;
            break;
          }
        }

        chatRef ??= await FirebaseFirestore.instance.collection('chats').add({
          'participants': [currentUser.uid, targetUid],
          'lastMessage': '',
          'createdAt': DateTime.now(),
        });

        await chatRef.collection('messages').add({
          'text': "Tu código de verificación es: $code",
          'senderId': currentUser.uid,
          'timestamp': DateTime.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Código enviado por mensaje a $targetEmail"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (_) {
      // El mensaje por chat falló, pero el código ya está guardado
      // El modal se mostrará de todas formas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Código generado. Entrégalo manualmente a $targetEmail: $code"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 8),
          ),
        );
      }
    }

    // ── Paso 3: Mostrar modal de verificación (siempre) ──────────────
    if (mounted) {
      _showCodeDialog(targetEmail);
    }
  }

  /// Mostrar diálogo para ingresar código
  void _showCodeDialog(String targetEmail) {
    final TextEditingController _codeController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Verificación",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ingresa el código de 6 dígitos que fue enviado a $targetEmail para habilitar el control.",
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor, letterSpacing: 2.0),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "Código recibido",
                labelStyle: TextStyle(color: Colors.grey, letterSpacing: 0),
                prefixIcon: Icon(Icons.password, color: Colors.blueAccent),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Validar", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              final enteredCode = _codeController.text.trim();

              if (enteredCode.isEmpty) return;

              final snapshot = await FirebaseFirestore.instance
                  .collection('codes')
                  .where('targetEmail', isEqualTo: targetEmail)
                  .get();

              if (snapshot.docs.isNotEmpty) {
                // Ordenar localmente
                final docs = snapshot.docs.toList();
                docs.sort((a, b) {
                  final aTime =
                      (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });

                if (docs.first['code'] == enteredCode) {
                  await FirebaseFirestore.instance.collection('control').add({
                    'correo_tutor': widget.currentUserEmail,
                    'correo_menor': targetEmail,
                    'createdAt': DateTime.now(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Usuario agregado con éxito"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                  _checkControls();
                  setState(() {
                    searchResults.clear();
                    _searchController.clear();
                  });
                  return;
                }
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Código inválido"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.blue.withOpacity(0.05);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Ajustes",
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: widget.onToggleTheme,
            tooltip: "Cambiar tema",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1A1A2E), Color(0xFF16213E)]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              _buildSectionHeader("Cuenta", textColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.logout, color: Colors.redAccent),
                    ),
                    title: Text(
                      "Cerrar Sesión",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
                    subtitle: Text(widget.currentUserEmail,
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    onTap: _logout,
                  ),
                ),
              ),

              SizedBox(height: 10),

              _buildSectionHeader("Seguridad Familiar", textColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    if (currentUserAge != null && currentUserAge! < 18)
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Icon(Icons.security, color: Colors.grey, size: 28),
                        title: Text("Control parental",
                            style: TextStyle(
                                color: Colors.grey, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            "Función no disponible para menores de edad.",
                            style: TextStyle(fontSize: 13)),
                        trailing: Icon(Icons.block, color: Colors.grey),
                      )
                    else
                      SwitchListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        secondary: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: parentalControl
                                ? Colors.blueAccent.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: parentalControl
                                ? Colors.blueAccent
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          "Modo Tutor",
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Habilita la supervisión de cuentas",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        value: parentalControl,
                        activeColor: Colors.blueAccent,
                        onChanged: (value) async {
                          setState(() {
                            parentalControl = value;
                            if (!value) searchResults.clear();
                          });
                          await _saveParentalControl(value);
                        },
                      ),
                  ],
                ),
              ),

              if (parentalControl && (currentUserAge == null || currentUserAge! >= 18)) ...[
                SizedBox(height: 24),
                _buildSectionHeader("Vincular Nueva Cuenta", textColor),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Correo del menor",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                          suffixIcon: isSearching
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.blueAccent)),
                                )
                              : IconButton(
                                  icon: Icon(Icons.search, color: Colors.blueAccent),
                                  onPressed: _searchUsers,
                                ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        onSubmitted: (_) => _searchUsers(),
                      ),
                      if (searchResults.isNotEmpty) ...[
                        SizedBox(height: 16),
                        ...searchResults.map((user) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.03)
                                    : Colors.blue.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.blue.shade100),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark
                                      ? Colors.blueAccent.withOpacity(0.2)
                                      : Colors.blue.shade100,
                                  child: Icon(Icons.person,
                                      color: Colors.blueAccent, size: 20),
                                ),
                                title: Text(user['email'] ?? 'Sin email',
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text("Edad: ${user['edad']} años",
                                    style: TextStyle(color: Colors.grey)),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(Icons.add_link, size: 18),
                                  label: Text("Vincular"),
                                  onPressed: () => _requestCode(user['email']),
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],

              if (hasControls) ...[
                SizedBox(height: 24),
                _buildSectionHeader("Cuentas Supervisadas", textColor),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.indigoAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewControlPage(
                              currentUserEmail: widget.currentUserEmail,
                              onToggleTheme: widget.onToggleTheme,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.dashboard_customize,
                                  color: Colors.white),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Panel de Control",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Gestionar y ver analíticas de menores",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
