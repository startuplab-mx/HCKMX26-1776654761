import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'detail_control_page.dart';

class ViewControlPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String currentUserEmail;

  ViewControlPage(
      {required this.onToggleTheme, required this.currentUserEmail});

  @override
  _ViewControlPageState createState() => _ViewControlPageState();
}

class _ViewControlPageState extends State<ViewControlPage> {
  late Future<QuerySnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.currentUserEmail)
        .limit(1)
        .get();
  }

  Widget _buildControlRecords() {
    return FutureBuilder<QuerySnapshot>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        String username = "Cargando...";
        if (userSnapshot.connectionState == ConnectionState.done) {
          if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
            final userData =
                userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
            username = userData['username'] ?? "Sin Nombre";
          } else {
            username = "Usuario Desconocido";
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('control')
              .where('correo_tutor', isEqualTo: widget.currentUserEmail)
              .snapshots(),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text("Error al cargar los datos.",
                      style: TextStyle(color: textColor)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 80, color: Colors.grey.withOpacity(0.5)),
                    SizedBox(height: 16),
                    Text(
                      "No se encontraron registros",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Los menores bajo tu control aparecerán aquí.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final docId = docs[index].id;

                return ControlCard(
                  key: ValueKey(docId),
                  data: data,
                  index: index,
                  username: username,
                  docId: docId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailControlPage(
                          currentUserEmail: widget.currentUserEmail,
                          onToggleTheme: widget.onToggleTheme,
                          controlData: data,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Panel de Control",
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            )
                          ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isDark
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.blue.shade100,
                        child: Icon(Icons.person,
                            size: 30, color: Colors.blueAccent),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tutor Principal",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              authProvider.user?.email ??
                                  widget.currentUserEmail,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  "Cuentas Supervisadas",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                ),
              ),
              Expanded(
                child: _buildControlRecords(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final String username;
  final String docId;
  final VoidCallback onTap;

  ControlCard({
    Key? key,
    required this.data,
    required this.index,
    required this.username,
    required this.docId,
    required this.onTap,
  }) : super(key: key);

  @override
  _ControlCardState createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  Future<QuerySnapshot>? _menorFuture;

  @override
  void initState() {
    super.initState();
    final correoMenor = widget.data['correo_menor'] as String?;
    if (correoMenor != null && correoMenor.isNotEmpty) {
      _menorFuture = FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: correoMenor)
          .limit(1)
          .get();
    }
  }

  void _deleteControl(bool isDark) async {
    final textColor = isDark ? Colors.white : Colors.black87;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Eliminar control", style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
            "¿Estás seguro de que deseas eliminar este registro de control y dejar de supervisar esta cuenta?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Eliminar", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('control')
          .doc(widget.docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registro eliminado correctamente"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_menorFuture == null) return SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return FutureBuilder<QuerySnapshot>(
      future: _menorFuture,
      builder: (context, menorSnapshot) {
        String nombreMenor = "Cargando...";
        bool isAdult = false;
        String? avatarUrl;

        if (menorSnapshot.connectionState == ConnectionState.done) {
          if (menorSnapshot.hasData && menorSnapshot.data!.docs.isNotEmpty) {
            final menorData =
                menorSnapshot.data!.docs.first.data() as Map<String, dynamic>;
            nombreMenor = menorData['username'] ?? "Sin Nombre";
            avatarUrl = menorData['profileImageUrl'];

            final edad = menorData['edad'] ?? 0;
            if (edad >= 18) {
              isAdult = true;
            }
          } else {
            nombreMenor = "Usuario Desconocido";
          }
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: isAdult
                ? (isDark ? Colors.grey[850] : Colors.grey[300])
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark || isAdult
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    )
                  ],
            border: isAdult
                ? null
                : Border.all(
                    color:
                        isDark ? Colors.white12 : Colors.blue.withOpacity(0.1),
                    width: 1,
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isAdult ? null : widget.onTap,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isAdult
                              ? Colors.grey
                              : (isDark
                                  ? Colors.blueAccent.withOpacity(0.2)
                                  : Colors.blue.shade50),
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  nombreMenor.isNotEmpty
                                      ? nombreMenor[0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isAdult
                                        ? Colors.white
                                        : Colors.blueAccent,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreMenor,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAdult
                                      ? Colors.grey
                                      : textColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    size: 14,
                                    color: isAdult ? Colors.grey : Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Tutor: ${widget.username}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isAdult
                                            ? Colors.grey
                                            : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: isAdult ? Colors.grey : Colors.redAccent),
                          onPressed: () => _deleteControl(isDark),
                          tooltip: "Eliminar control",
                        ),
                        if (!isAdult)
                          Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    if (isAdult)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "El usuario ya es mayor de edad. El control ha sido deshabilitado.",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
