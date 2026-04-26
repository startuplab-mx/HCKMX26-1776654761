import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'feed_page.dart';

const String _avisoPrivacidad = '''AVISO DE PRIVACIDAD PARA USUARIOS DE LA APLICACIÓN SENTINELA
Mecanismo de Detección Temprana de Riesgos para la Protección Digital

El presente Aviso de Privacidad rige el uso de la aplicación SENTINELA Protección Digital Soberana. Al registrarse y utilizar nuestros servicios, usted (en adelante, el "Usuario" o "Titular") acepta los términos aquí descritos, diseñados estrictamente como un mecanismo de detección temprana de riesgos para la protección de menores, operando bajo el principio de Privacidad por Diseño.

I. IDENTIDAD DEL RESPONSABLE
El responsable del tratamiento de los datos es la empresa UTECH.
Contacto: soporte@utech.com

II. NATURALEZA DEL SERVICIO: PREVENCIÓN Y PROTECCIÓN
SENTINELA no es una herramienta de vigilancia o invasión a la privacidad, sino un sistema preventivo. Operamos como un facilitador técnico ciego. Mediante una arquitectura "Zero-Knowledge" (Conocimiento Cero), las llaves de cifrado residen únicamente en usted, siendo técnicamente imposible para nosotros acceder al contenido cifrado. Todo el análisis automatizado ocurre exclusivamente en el dispositivo de origen (Edge AI).

III. BASE DE LEGITIMACIÓN E INTERÉS SUPERIOR DE LA NIÑEZ
El uso de esta aplicación se fundamenta en el Interés Superior de la Niñez, consagrado en el Artículo 4º Constitucional y la Ley General de los Derechos de Niñas, Niños y Adolescentes (LGDNNA). El objetivo principal de SENTINELA es priorizar la protección de menores, permitiendo la intervención oportuna de tutores o autoridades cuando exista un riesgo a su integridad física, psicológica o digital.

Asimismo, se reconoce que el Sistema Nacional para el Desarrollo Integral de la Familia (DIF) y los Sistemas de Protección Integral cuentan con atribuciones legales para intervenir como representantes en casos de vulneración de derechos de menores de edad, y pueden recibir información generada por este mecanismo para activar medidas de protección.

IV. EXCEPCIONES AL CONSENTIMIENTO EN PROTECCIÓN DE DERECHOS
El tratamiento de datos personales sin consentimiento se justifica conforme a las excepciones previstas en la legislación aplicable, al actualizarse supuestos de protección a la integridad y seguridad de personas menores de edad, así como la salvaguarda de derechos fundamentales, bajo un esquema de intervención mínima, proporcional y orientada exclusivamente a la prevención de riesgos.

Esta excepción se fundamenta en la protección de la vida y la integridad contemplada en la normatividad mexicana, permitiendo el uso de la herramienta para salvaguardar a personas en situación de vulnerabilidad.

V. OBLIGACIÓN DE DENUNCIA Y USO LEGÍTIMO
Como Usuario, usted reconoce que el Código Nacional de Procedimientos Penales (CNPP) establece que cualquier persona que tenga conocimiento de un posible delito está obligada a denunciarlo. En casos que involucren riesgos severos contra menores, la omisión puede generar responsabilidades legales para usted. SENTINELA actúa únicamente como su herramienta de detección temprana para facilitarle el cumplimiento de este deber de cuidado.

VI. PROHIBICIÓN EXPRESA DE VIGILANCIA INJUSTIFICADA
Queda estrictamente prohibido utilizar esta aplicación para vigilar a adultos capaces, cónyuges o empleados sin su consentimiento explícito. El uso de SENTINELA fuera del marco de la prevención y protección de menores constituye una violación grave a la Ley Federal de Delitos Informáticos, lo cual rescinde el contrato de forma inmediata e ipso jure, sujetando al Titular a responsabilidad civil y penal.

VII. DATOS RECABADOS Y LICENCIA DE USO
Para brindarle el servicio y permitirle ejercer sus funciones de cuidado y prevención, recabamos exclusivamente la información mínima indispensable:

• Datos de la cuenta del tutor: Correo electrónico y un nombre o seudónimo, utilizados única y exclusivamente para la creación, administración y recuperación de su cuenta como tutor legal responsable. No requerimos información fiscal ni datos sensibles.

• Registros de acceso seguro: Información técnica básica (como fecha y hora en que usted ingresa a su cuenta) requerida estrictamente para proteger su sesión contra accesos no autorizados y garantizar el correcto funcionamiento de la aplicación.

• Metadatos preventivos y alertas de contexto (del dispositivo protegido): El sistema analiza la actividad de forma automatizada y transitoria mediante filtros de seguridad para detectar posibles amenazas. No almacenamos, no conservamos ni tenemos acceso humano a los mensajes originales, fotos o comunicaciones privadas. Cuando el sistema detecta un riesgo, el contenido original se descarta de manera inmediata e irreversible, transformándose únicamente en una "alerta de contexto". Al utilizar el servicio, usted nos otorga una licencia no exclusiva y libre de regalías para usar estos patrones y contextos anonimizados con el único fin de entrenar y mejorar nuestros modelos preventivos de Inteligencia Artificial en beneficio de la seguridad de los menores.

VIII. DERECHOS DEL MENOR MONITOREADO
Al alcanzar la mayoría de edad legalmente establecida, el usuario monitoreado adquiere el derecho absoluto de solicitar la desvinculación de su perfil y la destrucción certificada de todos sus datos conductuales. UTECH priorizará en todo momento el derecho a la privacidad del individuo sobre la facultad de monitoreo del Titular.

IX. DERECHOS ARCO
Como Titular de la cuenta, usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse (Derechos ARCO) al tratamiento de los datos de su registro. Para ejercer estos derechos, resolver dudas o reportar incidentes, envíe su solicitud al correo: soporte@utech.com. Responderemos en un plazo máximo de 20 días hábiles.''';

const String _terminosCondiciones = '''TÉRMINOS Y CONDICIONES DE USO – SENTINELA
Plataforma de Detección Temprana de Riesgos para la Protección Digital

1. ACEPTACIÓN DE LOS TÉRMINOS
Al descargar, instalar, registrarse o utilizar la aplicación SENTINELA (en adelante, el "Servicio" o la "Aplicación"), usted (en adelante, el "Usuario" o "Tutor") acepta someterse íntegramente a los presentes Términos y Condiciones, así como a nuestro Aviso de Privacidad. Si no está de acuerdo con estos términos, no debe utilizar la Aplicación. Este Servicio es provisto por UTECH.

2. NATURALEZA Y PROPÓSITO DEL SERVICIO
SENTINELA es una herramienta preventiva de software diseñada exclusivamente para coadyuvar en la protección de menores de edad en entornos digitales, fundamentada en el Interés Superior de la Niñez. La Aplicación utiliza algoritmos de análisis en el dispositivo (Edge AI) para detectar posibles factores de riesgo (acoso, violencia, contenido inapropiado) y emitir "alertas de contexto" al Tutor, sin almacenar ni transmitir el contenido original de las comunicaciones privadas.

3. DECLARACIONES Y OBLIGACIONES DEL USUARIO (TUTOR)
Al utilizar SENTINELA, el Usuario declara bajo protesta de decir verdad y garantiza que:
• Es el padre, madre o tutor legal del menor de edad cuyo dispositivo será asociado al Servicio, contando con la patria potestad o tutela legal correspondiente en su jurisdicción.
• Instalará y utilizará la Aplicación únicamente en dispositivos sobre los cuales tiene propiedad o derecho legal de administración.
• Utilizará el Servicio con el propósito único y exclusivo de proteger la integridad física, psicológica y digital del menor, de forma proporcional y orientada a la prevención de riesgos.
• Comprende su obligación legal (establecida en el Código Nacional de Procedimientos Penales) de denunciar ante las autoridades competentes cualquier posible delito del que tenga conocimiento mediante el uso de esta herramienta.

4. USOS ESTRICTAMENTE PROHIBIDOS
El Usuario reconoce que el Servicio no es una herramienta de espionaje. Queda terminante y expresamente prohibido:
• Instalar la Aplicación en dispositivos de adultos con capacidad legal (incluyendo, pero no limitado a: cónyuges, parejas, empleados, colegas o amigos) sin su consentimiento expreso y por escrito.
• Utilizar la Aplicación para acechar, hostigar, extorsionar o vulnerar la privacidad de terceros.
• Intentar eludir las medidas de seguridad, la arquitectura "Zero-Knowledge" o realizar ingeniería inversa sobre la Aplicación.
El incumplimiento de esta cláusula constituye un uso ilegal de la plataforma y resultará en la cancelación inmediata e irreversible de la cuenta, reservándose UTECH el derecho de colaborar con las autoridades en caso de que se configure un delito informático.

5. LIMITACIÓN DE RESPONSABILIDAD (DISCLAIMER)
• Herramienta de Apoyo: SENTINELA funciona como un mecanismo de detección temprana basado en Inteligencia Artificial. UTECH no garantiza que la Aplicación detectará el 100% de los riesgos o comportamientos anómalos.
• Sin Asesoría Profesional: Las "alertas de contexto" generadas no constituyen diagnósticos psicológicos, médicos ni asesoría legal. La interpretación de las alertas y las acciones derivadas son responsabilidad exclusiva del Tutor.
• Fallas Técnicas: UTECH proporciona la Aplicación "tal cual" (as is) y no se hace responsable por interrupciones del servicio derivadas de fallos de red o incompatibilidad de hardware.

6. DERECHOS DEL MENOR AL ALCANZAR LA MAYORÍA DE EDAD
El Usuario reconoce y acepta que, al momento en que el menor monitoreado alcance la mayoría de edad, este adquirirá el derecho inalienable de desvincular su dispositivo y solicitar la eliminación de cualquier metadato o patrón conductual asociado a su perfil. UTECH habilitará los mecanismos técnicos para garantizar este derecho.

7. PROPIEDAD INTELECTUAL
Todo el código, diseño, logotipos, algoritmos y elementos visuales de SENTINELA son propiedad exclusiva de UTECH. Se le otorga al Usuario una licencia de uso personal, intransferible y no exclusiva, limitada al tiempo que mantenga activa su cuenta.

8. MODIFICACIONES Y JURISDICCIÓN
UTECH se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios sustanciales serán notificados al correo registrado en su cuenta. Para la interpretación, cumplimiento y ejecución del presente contrato, las partes se someten expresamente a las leyes y tribunales competentes de los Estados Unidos Mexicanos, renunciando a cualquier otro fuero que pudiera corresponderles por razón de sus domicilios presentes o futuros.''';

class SignUpPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  SignUpPage({required this.onToggleTheme});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final usernameController = TextEditingController();
  final edadController = TextEditingController();

  bool _aceptoAviso = false;
  bool _aceptoTerminos = false;
  bool _isLoading = false;

  void _mostrarAvisoPrivacidad() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? Color(0xFF1E1E2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aviso de Privacidad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'SENTINELA – UTECH',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Texto del aviso con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    _avisoPrivacidad,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),

              // Pie del modal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'He leído y acepto el Aviso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _aceptoAviso = true);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarTerminos() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel_outlined, color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Términos y Condiciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'SENTINELA – UTECH',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Texto con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    _terminosCondiciones,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              // Botón aceptar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'He leído y acepto los Términos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _aceptoTerminos = true);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6,
                color: Theme.of(context).iconTheme.color),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 80,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Crea tu cuenta",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Regístrate para comenzar a usar la app",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 40),

              // Campos del formulario
              _buildTextField(
                controller: emailController,
                label: "Correo electrónico",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: usernameController,
                label: "Nombre de usuario",
                icon: Icons.person_outline,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: edadController,
                label: "Edad",
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: passController,
                label: "Contraseña",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              SizedBox(height: 28),

              // ── Bloque Aviso de Privacidad ────────────────────────────
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _aceptoAviso
                      ? Colors.green.withOpacity(0.07)
                      : (isDark
                          ? Colors.blueAccent.withOpacity(0.07)
                          : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _aceptoAviso
                        ? Colors.green.withOpacity(0.5)
                        : Colors.blueAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título sección
                    Row(
                      children: [
                        Icon(
                          _aceptoAviso
                              ? Icons.verified_user_outlined
                              : Icons.policy_outlined,
                          size: 20,
                          color: _aceptoAviso
                              ? Colors.green
                              : Colors.blueAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aviso de Privacidad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _aceptoAviso
                                ? Colors.green
                                : Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Para cumplir con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) y proteger tus derechos, es necesario que conozcas cómo utilizamos tu información.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Botón leer aviso completo
                    GestureDetector(
                      onTap: _mostrarAvisoPrivacidad,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new,
                                size: 15, color: Colors.blueAccent),
                            SizedBox(width: 6),
                            Text(
                              'Leer Aviso de Privacidad Completo',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14),

                    // Checkbox de aceptación
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _aceptoAviso = !_aceptoAviso),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _aceptoAviso
                                  ? Colors.green
                                  : Colors.transparent,
                              border: Border.all(
                                color: _aceptoAviso
                                    ? Colors.green
                                    : Colors.blueAccent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _aceptoAviso
                                ? Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          'He leído y acepto el '),
                                  TextSpan(
                                    text: 'Aviso de Privacidad',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                      text:
                                          ', incluyendo el tratamiento de mis datos personales conforme a lo descrito.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ─────────────────────────────────────────────────────────

              SizedBox(height: 16),

              // ── Bloque Términos y Condiciones ─────────────────────────
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _aceptoTerminos
                      ? Colors.green.withOpacity(0.07)
                      : (isDark
                          ? Colors.purple.withOpacity(0.07)
                          : Colors.purple.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _aceptoTerminos
                        ? Colors.green.withOpacity(0.5)
                        : Colors.purpleAccent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(
                          _aceptoTerminos
                              ? Icons.verified_outlined
                              : Icons.gavel_outlined,
                          size: 20,
                          color: _aceptoTerminos
                              ? Colors.green
                              : Colors.purpleAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Términos y Condiciones',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _aceptoTerminos
                                ? Colors.green
                                : Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Al registrarte aceptas las condiciones de uso legítimo del servicio, incluyendo las restricciones de uso, la limitación de responsabilidad y la jurisdicción aplicable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Botón leer
                    GestureDetector(
                      onTap: _mostrarTerminos,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new, size: 15, color: Colors.purpleAccent),
                            SizedBox(width: 6),
                            Text(
                              'Leer Términos y Condiciones Completos',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    // Checkbox
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _aceptoTerminos = !_aceptoTerminos),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _aceptoTerminos ? Colors.green : Colors.transparent,
                              border: Border.all(
                                color: _aceptoTerminos ? Colors.green : Colors.purpleAccent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _aceptoTerminos
                                ? Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(text: 'He leído y acepto los '),
                                  TextSpan(
                                    text: 'Términos y Condiciones de Uso',
                                    style: TextStyle(
                                      color: Colors.purpleAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: ', incluyendo las restricciones y obligaciones como Tutor.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ─────────────────────────────────────────────────────────

              SizedBox(height: 28),

              // Botón de registro
              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: (_aceptoAviso && _aceptoTerminos) ? 1.0 : 0.45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: (_aceptoAviso && _aceptoTerminos) ? primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
                    elevation: (_aceptoAviso && _aceptoTerminos) ? 5 : 0,
                  ),
                  onPressed: (_aceptoAviso && _aceptoTerminos) && !_isLoading
                      ? () async {
                          setState(() => _isLoading = true);
                          try {
                            final userCredential = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                              email: emailController.text.trim(),
                              password: passController.text.trim(),
                            );

                            if (userCredential.user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userCredential.user!.uid)
                                  .set({
                                'email': userCredential.user!.email,
                                'username': usernameController.text.trim(),
                                'edad':
                                    int.tryParse(edadController.text.trim()) ??
                                        0,
                                'aceptoAvisoPrivacidad': true,
                                'fechaAceptacionAviso': DateTime.now(),
                                'aceptoTerminosCondiciones': true,
                                'fechaAceptacionTerminos': DateTime.now(),
                                'createdAt': DateTime.now(),
                              });

                              // Navegar al feed limpiando todo el stack de navegación
                              if (mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => FeedPage(
                                      onToggleTheme: widget.onToggleTheme,
                                    ),
                                  ),
                                  (route) => false, // elimina todas las rutas anteriores
                                );
                              }
                            }
                          } on FirebaseAuthException catch (e) {
                            String mensaje;
                            switch (e.code) {
                              case 'email-already-in-use':
                                mensaje = "El correo ya está registrado.";
                                break;
                              case 'invalid-email':
                                mensaje = "El correo no es válido.";
                                break;
                              case 'weak-password':
                                mensaje =
                                    "La contraseña es demasiado débil.";
                                break;
                              case 'operation-not-allowed':
                                mensaje =
                                    "La autenticación por correo y contraseña no está habilitada.";
                                break;
                              default:
                                mensaje = "Error de Auth: \${e.code}";
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(mensaje),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: \$e"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Registrarse",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (!_aceptoAviso)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(
                        'Debes aceptar el aviso para continuar',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}