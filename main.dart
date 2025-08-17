import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const AlgebraBotApp());

/// Colores de la maqueta
const Color kBlue = Color(0xFF0E4A85);
const Color kBlueDark = Color(0xFF0B3C6A);
const Color kOrange = Color(0xFFF39C12);
const Color kTextWhite = Colors.white;

class AlgebraBotApp extends StatelessWidget {
  const AlgebraBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Bot - Álgebra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBlue,
        primaryColor: kBlue,
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: kTextWhite,
          displayColor: kTextWhite,
        ),
      ),
      home: const ChatAlgebraPage(),
    );
  }
}

class ChatAlgebraPage extends StatefulWidget {
  const ChatAlgebraPage({super.key});

  @override
  State<ChatAlgebraPage> createState() => _ChatAlgebraPageState();
}

class _ChatAlgebraPageState extends State<ChatAlgebraPage>
    with TickerProviderStateMixin {
  final List<_Msg> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _inputCtrl = TextEditingController();

  late final AnimationController _ctaArrowCtrl;
  late final Animation<double> _ctaArrowScale;

  @override
  void initState() {
    super.initState();

    _ctaArrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _ctaArrowScale = Tween(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _ctaArrowCtrl, curve: Curves.easeInOut),
    );

    _seedDemo();
  }

  @override
  void dispose() {
    _ctaArrowCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _seedDemo() async {
    final demo = <_Msg>[
      _Msg.bot("🐯  Observa el ejemplo de pregunta:"),
      _Msg.bot("¿Cómo puedo resolver la ecuación 3x - 7 = 11?"),
      _Msg.note(
        "Tu pregunta: ayúdame con la eq 3x - 7 = 11\n\n"
            "Para resolver la ecuación 3x - 7 = 11, seguiremos estos pasos:\n\n"
            "Paso 1: Aislar el término con 'x'.\n"
            "Sumamos 7 a ambos lados:\n\n"
            "         3x - 7 + 7 = 11 + 7\n"
            "         3x = 18\n\n"
            "Paso 2: Despejar x.\n"
            "Dividimos entre 3:\n\n"
            "         x = 18 / 3 = 6",
      ),
    ];

    for (final m in demo) {
      await Future.delayed(const Duration(milliseconds: 450));
      _insertMessage(m);
    }
  }

  void _insertMessage(_Msg m) {
    _messages.add(m);
    _listKey.currentState?.insertItem(_messages.length - 1,
        duration: const Duration(milliseconds: 300));
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    _insertMessage(_Msg.user(text.trim()));
    _inputCtrl.clear();

    final typingId = UniqueKey();
    final typing = _Msg.typing(key: typingId);
    _insertMessage(typing);

    // Llamamos a API
    final respuesta = await obtenerRespuesta(text);

    // Quitamos "escribiendo..."
    final idx = _messages.indexWhere((m) => m.key == typingId);
    if (idx != -1) {
      setState(() {
        _messages.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx,
              (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: _MessageBubble(msg: typing),
          ),
          duration: const Duration(milliseconds: 150),
        );
      });
    }

    // Insertamos respuesta real con formato tipo _Msg.note
    _insertMessage(_Msg.note(
      "Tu pregunta: $text\n\n"
          "$respuesta",
    ));
  }

  Future<String> obtenerRespuesta(String pregunta) async {
    final url = Uri.parse("http://10.50.116.214:5000/preguntar"); // servidor Flask
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pregunta": pregunta}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //respuesta correcta desde Flask
      return data['respuesta'] ?? "No obtuve respuesta del servidor";
    } else {
      //en caso de error, devuelves un mensaje
      throw Exception("Error en el servidor: ${response.statusCode}");
    }
  }

  Future<void> _openAskSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBlueDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 18,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hazme una pregunta de Álgebra",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: kTextWhite),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inputCtrl,
                maxLines: null,
                style: const TextStyle(color: kTextWhite),
                cursorColor: kOrange,
                decoration: InputDecoration(
                  hintText: "Escribe aquí…",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kOrange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        final text = _inputCtrl.text;
                        Navigator.of(ctx).pop();
                        _sendUserMessage(text);
                      },
                      child: const Text(
                        "Enviar",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              decoration: const BoxDecoration(
                color: kBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back, color: kTextWhite),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          "CHAT BOT – ÁLGEBRA",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Text("🐯", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "BIENVENIDO A CHAT BOT – ÁLGEBRA",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zona de chat
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: kBlueDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: AnimatedList(
                  key: _listKey,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  initialItemCount: _messages.length,
                  itemBuilder: (context, index, animation) {
                    final msg = _messages[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _MessageBubble(msg: msg),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: GestureDetector(
          onTap: _openAskSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A77C7), Color(0xFF264F8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, color: kTextWhite),
                const SizedBox(width: 10),
                const Text(
                  "HAZME UNA PREGUNTA",
                  style: TextStyle(
                    color: kTextWhite,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                ScaleTransition(
                  scale: _ctaArrowScale,
                  child: const Icon(Icons.expand_less, color: kOrange),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo de mensaje + tipos
class _Msg {
  final Key? key;
  final String text;
  final _MsgType type;

  const _Msg._(this.text, this.type, {this.key});

  factory _Msg.user(String t) => _Msg._(t, _MsgType.user);
  factory _Msg.bot(String t) => _Msg._(t, _MsgType.bot);
  factory _Msg.note(String t) => _Msg._(t, _MsgType.note);
  factory _Msg.typing({Key? key}) => _Msg._("typing", _MsgType.typing, key: key);
}

enum _MsgType { user, bot, note, typing }

/// Burbuja visual + animaciones de texto
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.type == _MsgType.user;
    final isBot = msg.type == _MsgType.bot;
    final isNote = msg.type == _MsgType.note;
    final isTyping = msg.type == _MsgType.typing;

    final bubbleColor = isBot
        ? kOrange
        : isUser
        ? Colors.white10
        : isNote
        ? Colors.transparent
        : Colors.white10;

    final textColor = isBot ? Colors.black : kTextWhite;

    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    Widget content;
    if (isTyping) {
      content = const _TypingBubble();
    } else if (isNote) {
      content = Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: kTextWhite,
            fontFamily: 'monospace',
            height: 1.35,
          ),
          child: TypewriterText(
            text: msg.text,  // <- CORREGIDO
            speed: const Duration(milliseconds: 18),
            chunk: 2,
          ),
        ),
      );
    } else {
      content = Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.25,
            fontWeight: isBot ? FontWeight.w700 : FontWeight.w500,
          ),
          child: isBot
              ? TypewriterText(
            text: msg.text,  // <- CORREGIDO
            speed: const Duration(milliseconds: 18),
          )
              : Text(msg.text),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 80 : 8,
        right: isUser ? 8 : 80,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (isBot)
            const Padding(
              padding: EdgeInsets.only(bottom: 6, left: 6),
              child: _AvatarBot(),
            ),
          content,
        ],
      ),
    );
  }
}

/// Avatar del bot
class _AvatarBot extends StatefulWidget {
  const _AvatarBot();

  @override
  State<_AvatarBot> createState() => _AvatarBotState();
}

class _AvatarBotState extends State<_AvatarBot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0,
      upperBound: 6,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_ctrl.value),
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white24,
            child: Text("🐯", style: TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}

/// Burbujita de “escribiendo…”
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotCtrls;

  @override
  void initState() {
    super.initState();
    _dotCtrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
        lowerBound: 0.4,
        upperBound: 1.0,
      )..repeat(
        reverse: true,
        period: const Duration(milliseconds: 900),
      ),
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _dotCtrls[1].forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _dotCtrls[2].forward();
    });
  }

  @override
  void dispose() {
    for (final c in _dotCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return ScaleTransition(
            scale:
            CurvedAnimation(parent: _dotCtrls[i], curve: Curves.easeInOut),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                "•",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Texto con efecto “typewriter”
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;
  final int chunk;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 22),
    this.chunk = 1,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late Timer _timer;
  int _idx = 0;
  String _displayed = "";

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.speed, (timer) {
      setState(() {
        final end = (_idx + widget.chunk <= widget.text.length)
            ? _idx + widget.chunk
            : widget.text.length;
        _displayed = widget.text.substring(0, end);
        _idx = end;
        if (_idx >= widget.text.length) _timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed);
  }
}
