import 'coffee_app.dart';
import 'src/coffee.dart';

Future<void> main() async {
  final CoffeeApp coffeeApp = await CoffeeApp.create();
  final CoffeeMaker coffeeMaker = coffeeApp.getCoffeeMaker();
  coffeeMaker.brew();
}