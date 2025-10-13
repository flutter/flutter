import 'package:flutter/material.dart';

class ComponentsPage extends StatelessWidget {
 const ComponentsPage({super.key});

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: const Text('Componentes')),
     body: const Center(),
   );
 }
}
import 'package:flutter/material.dart';

class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Componentes'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1 - Card
            const Text(
              '1 - Card',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Card(
              elevation: 2,
              color: Colors.deepPurple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Texto de exemplo.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2 - Container
            const Text(
              '2 - Container',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple, width: 2),
              ),
              child: const Text(
                'Este é um Container com margem externa (margin), '
                'espaçamento interno (padding) e borda (border).',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // 3 - ListView
            const Text(
              '3 - ListView',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(
              height: 120,
              child: Scrollbar(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(
                    6,
                    (index) => Container(
                      width: 100,
                      margin: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[100 * ((index % 8) + 1)],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Item ${index + 1}'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4 - GridView
            const Text(
              '4 - GridView',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                6,
                (index) => Card(
                  color: Colors.deepPurple.shade100,
                  child: Center(child: Text('Grid ${index + 1}')),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5 - Stack
            const Text(
              '5 - Stack',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              height: 150,
              color: Colors.deepPurple.shade50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 100,
                    color: Colors.deepPurple.shade200,
                  ),
                  const Positioned(
                    top: 20,
                    child: Icon(Icons.star, size: 40, color: Colors.white),
                  ),
                  const Text('Stack com elementos sobrepostos'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6 - ConstrainedBox
            const Text(
              '6 - ConstrainedBox',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Center(
              child: Container(
                color: Colors.deepPurple.shade50,
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 250,
                    minHeight: 80,
                    maxHeight: 100,
                  ),
                  child: Container(
                    color: Colors.deepPurple.shade200,
                    alignment: Alignment.center,
                    child: const Text(
                      'Este espaço está limitado\n'
                      'a no máximo 250x100 pixels.\n'
                      'O conteúdo não pode ultrapassar\n'
                      'esses limites.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 7 - SingleChildScrollView
            const Text(
              '7 - SingleChildScrollView',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    20,
                    (index) => Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Linha de texto ${index + 1}'),
                    ),
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