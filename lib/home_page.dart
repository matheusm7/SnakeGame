import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/highscore_tile.dart';
import 'package:snake_game/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum snake_Direction { UP, DOWN, LEFT, RIGHT }

class _HomePageState extends State<HomePage> {
  // tamanho da tela (quadrados)
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  // configurações do jogo
  bool gameHasStarted = false;
  final _nameController = TextEditingController();

  // pontuação inicial do usuário
  int currentScore = 0;

  // posição da cobra
  List<int> snakePos = [
    0,
    1,
    2,
  ];

  // direção inicial da cobra (direita)
  var currentDirection = snake_Direction.RIGHT;

  // posição inicial da comida
  int foodPos = 55;

  // lista com melhores pontuações
  List<String> highscore_DocIds = [];
  late final Future? letsGetDocIds;

  @override
  void initState() {
    letsGetDocIds = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance.collection("highscores").orderBy("score", descending: true).limit(10).get().then((value) => value.docs.forEach((element) {
          highscore_DocIds.add(element.reference.id);
        }));
  }

  // começar a partida
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        // manter a cobra em movimento
        moveSnake();
        // jogo perdido,
        if (gameOver()) {
          timer.cancel();

          // exibir mensagem para o usuário
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Você perdeu'),
                  content: Column(
                    children: [
                      Text('Você fez $currentScore pontos!'),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Enter name'),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        submitScore();
                        Navigator.pop(context);
                        newGame();
                      },
                      color: Colors.pink,
                      child: const Text('Submit'),
                    ),
                  ],
                );
              });
        }
      });
    });
  }

  void submitScore() {
    // acesso à colecção
    var database = FirebaseFirestore.instance;

    // add data para o firebase
    database.collection('highscores').add({
      "name": _nameController.text,
      "score": currentScore,
    });
  }

  // novo jogo
  Future newGame() async {
    highscore_DocIds = [];
    await getDocId();
    setState(() {
      snakePos = [
        0,
        1,
        2,
      ];
    });
    foodPos = 55;
    currentDirection = snake_Direction.RIGHT;
    gameHasStarted = false;
    currentScore = 0;
  }

  void eatFood() {
    currentScore++;
    // verificando se o alimento não esta no mesmo lugar onde a cobra esta
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case snake_Direction.RIGHT:
        {
          // adicionar um ponto a cobra
          // ajustar a parede para a cobra
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }
        break;
      case snake_Direction.LEFT:
        {
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }
        break;
      case snake_Direction.UP:
        {
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }
        }
        break;
      case snake_Direction.DOWN:
        {
          if (snakePos.last + rowSize > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }
        }
        break;
      default:
    }

    // cobra esta comendo a comida
    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      snakePos.removeAt(0);
    }
  }

  // você perdeu!
  bool gameOver() {
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);

    if (bodySnake.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 152, 152, 152),
      body: SizedBox(
        width: screenWidth > 428 ? 428 : screenWidth,
        child: Column(
          children: [
            // pontuações
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // pontuação atual
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        const Text(
                          'Sua pontuação',
                          style: TextStyle(fontSize: 25),
                        ),
                        Text(
                          currentScore.toString(),
                          style: const TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // melhores jogadores
                  Expanded(
                    child: gameHasStarted
                        ? Container()
                        : FutureBuilder(
                            future: letsGetDocIds,
                            builder: (context, snapshot) {
                              return ListView.builder(
                                itemCount: highscore_DocIds.length,
                                itemBuilder: (context, index) {
                                  return HighScoreTile(documentId: highscore_DocIds[index]);
                                },
                              );
                            },
                          ),
                  )
                ],
              ),
            ),

            // fundo do jogo
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 && currentDirection != snake_Direction.UP) {
                    currentDirection = snake_Direction.DOWN;
                  } else if (details.delta.dy < 0 && currentDirection != snake_Direction.DOWN) {
                    currentDirection = snake_Direction.UP;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 && currentDirection != snake_Direction.LEFT) {
                    currentDirection = snake_Direction.RIGHT;
                  } else if (details.delta.dx < 0 && currentDirection != snake_Direction.RIGHT) {
                    currentDirection = snake_Direction.LEFT;
                  }
                },
                child: GridView.builder(
                  itemCount: totalNumberOfSquares,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: rowSize),
                  itemBuilder: (context, index) {
                    if (snakePos.contains(index)) {
                      return const SnakePixel();
                    } else if (foodPos == index) {
                      return const FoodPixel();
                    } else {
                      return const BlankPixel();
                    }
                  },
                ),
              ),
            ),
            // botão de jogar
            Expanded(
              child: Container(
                child: Center(
                  child: MaterialButton(
                    color: gameHasStarted ? Colors.grey : Colors.pink,
                    onPressed: gameHasStarted ? () {} : startGame,
                    child: const Text('Jogar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
