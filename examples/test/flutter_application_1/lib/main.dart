import 'package:flutter/material.dart';

void main() {
  
  runApp(MyApp());
}
//add stateless widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true

      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  
  @override
  State<MyHomePage> createState()=> _MyHomePageState();
  
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0 ;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), 
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
         children: [
          const Text ('Jumlah Counter'),
          Text('$_counter',
          style: Theme.of(context).textTheme.headlineMedium,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _incrementCounter,
                  child: const Text('Tambah'),
                  ),
              ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                  onPressed: _decrementCounter,
                  child: const Text('Kurang'),
                  ),
                ),
            ],
          ),
         ],
        ),
      ),
      floatingActionButton: 
      Row(

        children: [
          
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
            ),
            FloatingActionButton(
            onPressed: _decrementCounter,
            tooltip: 'Decrement',
            child: const Icon(Icons.remove),
            ),

        ],
      )

    );
  }
}
