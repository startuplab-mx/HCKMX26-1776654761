import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailControlPage extends StatefulWidget {
  final String currentUserEmail;
  final VoidCallback onToggleTheme;
  final Map<String, dynamic> controlData;

  DetailControlPage({
    required this.currentUserEmail,
    required this.onToggleTheme,
    required this.controlData,
  });

  @override
  _DetailControlPageState createState() => _DetailControlPageState();
}

class _DetailControlPageState extends State<DetailControlPage> {
  Future<QuerySnapshot>? _menorFuture;

  @override
  void initState() {
    super.initState();
    final correoMenor = widget.controlData['correo_menor'] as String?;
    if (correoMenor != null && correoMenor.isNotEmpty) {
      _menorFuture = FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: correoMenor)
          .limit(1)
          .get();
    }
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFaseBar(int fase, bool isDark) {
    // Colores por fase (de menor a mayor peligro)
    final List<Color> faseColors = [
      Color(0xFF4CAF50), // Fase 1 – verde
      Color(0xFFFFB300), // Fase 2 – ámbar
      Color(0xFFFF7043), // Fase 3 – naranja
      Color(0xFFE53935), // Fase 4 – rojo
    ];

    final List<String> faseLabels = [
      'Reclutamiento',
      'Inducción',
      'Incubación',
      'Utilización',
    ];

    final Color inactiveColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Column(
      children: [
        // Etiquetas de fase
        Row(
          children: List.generate(4, (i) {
            final bool activa = i < fase;
            final Color labelColor = activa ? faseColors[i] : Colors.grey;
            return Expanded(
              child: Column(
                children: [
                  Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    faseLabels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: activa ? FontWeight.bold : FontWeight.normal,
                      color: labelColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
        SizedBox(height: 6),
        // Barra segmentada
        Row(
          children: List.generate(4, (i) {
            final bool activa = i < fase;
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                height: 10,
                decoration: BoxDecoration(
                  color: activa ? faseColors[i] : inactiveColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: activa
                      ? [
                          BoxShadow(
                            color: faseColors[i].withOpacity(0.4),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]
                      : [],
                ),
              ),
            );
          }),
        ),
        // Indicador de fase actual
        if (fase > 0 && fase <= 4)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 12, color: faseColors[fase - 1]),
                SizedBox(width: 4),
                Text(
                  'Fase $fase detectada: ${faseLabels[fase - 1]}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: faseColors[fase - 1],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final correoMenor = widget.controlData['correo_menor'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.blue.withOpacity(0.1);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Detalle de Control",
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: textColor),
            onPressed: widget.onToggleTheme,
            tooltip: "Cambiar tema",
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Información del Menor", textColor),
                if (_menorFuture != null)
                  FutureBuilder<QuerySnapshot>(
                    future: _menorFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent,
                            ),
                          ),
                        );
                      }

                      String nombreMenor = "Desconocido";
                      String menorId = "";
                      String? avatarUrl;

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final doc = snapshot.data!.docs.first;
                        final data = doc.data() as Map<String, dynamic>;
                        nombreMenor = data['username'] ?? "Sin Nombre";
                        avatarUrl = data['profileImageUrl'];
                        menorId = doc.id;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                )
                              ],
                              border: isDark
                                  ? Border.all(color: Colors.white12)
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: isDark
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.green.shade100,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(Icons.child_care,
                                            size: 35, color: Colors.green)
                                        : null,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombreMenor,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined,
                                                size: 14, color: Colors.grey),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                correoMenor ?? "Sin correo",
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          _buildSectionHeader("Detalles de Advertencias", textColor),
                          if (menorId.isNotEmpty)
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('alerts')
                                  .where(Filter.or(
                                    Filter('senderId', isEqualTo: menorId),
                                    Filter('otherUserId', isEqualTo: menorId),
                                  ))
                                  .snapshots(),
                              builder: (context, alertSnapshot) {
                                if (alertSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.blueAccent));
                                }
                                if (alertSnapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                          "Error al cargar advertencias.",
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  );
                                }
                                if (!alertSnapshot.hasData ||
                                    alertSnapshot.data!.docs.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: isDark
                                          ? Border.all(color: Colors.white12)
                                          : Border.all(
                                              color: Colors.blue.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 60, color: Colors.green),
                                        SizedBox(height: 16),
                                        Text(
                                          "Todo está en orden",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: textColor),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "No hay advertencias registradas para este menor.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Obtener y ordenar localmente por timestamp (descendente)
                                final alerts =
                                    alertSnapshot.data!.docs.toList();
                                alerts.sort((a, b) {
                                  final dataA =
                                      a.data() as Map<String, dynamic>;
                                  final dataB =
                                      b.data() as Map<String, dynamic>;
                                  final tA = dataA['timestamp'] as Timestamp?;
                                  final tB = dataB['timestamp'] as Timestamp?;
                                  if (tA == null && tB == null) return 0;
                                  if (tA == null) return 1;
                                  if (tB == null) return -1;
                                  return tB.compareTo(tA);
                                });

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: alerts.length,
                                  itemBuilder: (context, index) {
                                    return _buildAlertCard(context, alerts[index],
                                        widget.currentUserEmail);
                                  },
                                );
                              },
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "No se puede cargar el historial de advertencias sin el menor asignado.",
                                style: TextStyle(color: textColor),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person_off, color: Colors.white),
                      ),
                      title: Text("Sin Menor asignado",
                          style: TextStyle(color: textColor)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context, DocumentSnapshot alertDoc, String currentUserEmail) {
    final alert = alertDoc.data() as Map<String, dynamic>;
    final alertId = alertDoc.id;

    String nivel = alert['riskLevel'] ?? 'Desconocido';
    Color colorNivel = Colors.grey;
    if (nivel.toUpperCase() == 'CRITICO' || nivel.toUpperCase() == 'ALTO') {
      colorNivel = Colors.redAccent;
    } else if (nivel.toUpperCase() == 'MEDIO') {
      colorNivel = Colors.orange;
    } else if (nivel.toUpperCase() == 'BAJO') {
      colorNivel = Colors.blueAccent;
    } else if (nivel.toUpperCase() == 'NINGUNO') {
      colorNivel = Colors.green;
    }

    String senderId = alert['senderId'] ?? '';
    String mensaje = alert['message'] ?? '';

    // Obtener datos del rawResponse
    final rawResponse = alert['rawResponse'] as Map<String, dynamic>? ?? {};
    int faseReclutamiento = rawResponse['fase_reclutamiento'] ?? 0;
    
    List<dynamic> rawFlags = rawResponse['flags'] ?? [];
    List<String> flags = rawFlags.map((e) => e.toString()).toList();
    
    List<dynamic> rawTecnicas = rawResponse['tecnicas_identificadas'] ?? [];
    List<String> tecnicas = rawTecnicas.map((e) => e.toString()).toList();

    List<dynamic> rawActividades = rawResponse['actividades_relacionadas'] ?? [];
    List<String> actividades = rawActividades.map((e) => e.toString()).toList();

    String justificacion = rawResponse['justificacion_preventiva'] ?? '';
    String evidencia = alert['evidenciaCritica'] ?? rawResponse['evidencia_critica'] ?? '';

    bool isReported = alert['reported'] == true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ],
        border: isDark
            ? Border.all(color: colorNivel.withOpacity(0.3), width: 1)
            : Border.all(color: colorNivel.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nivel de Riesgo",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorNivel.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorNivel.withOpacity(0.5)),
                      ),
                      child: Text(
                        nivel.toUpperCase(),
                        style: TextStyle(
                            color: colorNivel,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                FutureBuilder<DocumentSnapshot>(
                    future: senderId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(senderId)
                            .get()
                        : null,
                    builder: (context, userSnap) {
                      String contactName = "@desconocido";
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final uData =
                            userSnap.data!.data() as Map<String, dynamic>?;
                        if (uData != null) {
                          contactName =
                              "@${uData['username'] ?? uData['email'] ?? 'desconocido'}";
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Contacto detectado",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  color: Colors.blueAccent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                contactName,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ],
                          )
                        ],
                      );
                    }),
              ],
            ),
            SizedBox(height: 20),

            // Barra de Fase de Reclutamiento segmentada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fase de Reclutamiento",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                Icon(Icons.timeline, size: 16, color: Colors.grey),
              ],
            ),
            SizedBox(height: 12),
            _buildFaseBar(faseReclutamiento, isDark),
            SizedBox(height: 20),

            // Evidencia crítica
            if (evidencia.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Evidencia Crítica", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
                          SizedBox(height: 4),
                          Text(
                            evidencia,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            // Justificación preventiva
            if (justificacion.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Justificación Preventiva", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 13)),
                          SizedBox(height: 4),
                          Text(
                            justificacion,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            // Flags detectadas
            if (flags.isNotEmpty) ...[
              Text("Palabras/Frases de Alerta:",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[800])),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: flags
                    .map((flag) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_outlined,
                                  color: Colors.redAccent, size: 14),
                              SizedBox(width: 4),
                              Text(flag,
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
            ],

            // Técnicas identificadas
            if (tecnicas.isNotEmpty) ...[
              Text("Técnicas Identificadas:",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[800])),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tecnicas
                    .map((tech) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.1),
                            border: Border.all(
                                color: Colors.purpleAccent.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tech,
                              style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
            ],

            // Actividades relacionadas
            if (actividades.isNotEmpty) ...[
              Text("Actividades Relacionadas:",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[800])),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actividades
                    .map((act) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(act,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
            ],

            Divider(color: isDark ? Colors.white12 : Colors.black12),
            SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_chat_read_outlined,
                      color: Colors.blueAccent, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mensaje analizado:",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: textColor)),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300),
                        ),
                        child: Text(
                          "\"$mensaje\"",
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                              color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text("Eliminar"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor:
                            isDark ? Color(0xFF1A1A2E) : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text("Eliminar alerta",
                                style: TextStyle(color: textColor)),
                          ],
                        ),
                        content: Text(
                            "¿Estás seguro que deseas eliminar permanentemente esta notificación?",
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87)),
                        actions: [
                          TextButton(
                            child: Text("Cancelar",
                                style: TextStyle(color: Colors.grey)),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text("Eliminar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('alerts')
                                  .doc(alertId)
                                  .delete();
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReported ? Colors.grey : Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(isReported ? Icons.check : Icons.report_problem,
                      size: 18),
                  label: Text(isReported ? "Denunciado" : "Denunciar"),
                  onPressed: isReported
                      ? null
                      : () async {
                          // Guardar en coleccion reports
                          await FirebaseFirestore.instance
                              .collection('reports')
                              .add({
                            'alertId': alertId,
                            'reportedUserId': senderId,
                            'reportedBy': currentUserEmail,
                            'message': mensaje,
                            'timestamp': DateTime.now(),
                          });

                          // Marcar la alerta como reportada para evitar multiples denuncias
                          await FirebaseFirestore.instance
                              .collection('alerts')
                              .doc(alertId)
                              .update({
                            'reported': true,
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "El usuario ha sido denunciado correctamente."),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}