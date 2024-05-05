import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
 
class ParkingReservationView extends StatelessWidget {
  const ParkingReservationView({super.key});
 
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Reserve Parking Spot'),
      ),
      child: Center(
        child: ParkingGridView(),
      ),
    );
  }
}
 
class ParkingGridView extends StatelessWidget {
  const ParkingGridView({super.key});
 
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      children: List.generate(
        4,
        (index) => ParkingCard(
          location: 'Location $index',
          price: 'TND ${(1 + index * 0.5) * 2}/hr',
          hoursOfService: 'Open 24 hrs',
          onPressed: () {
            _showBookingForm(context, 'Location $index');
          },
        ),
      ),
    );
  }
 
  void _showBookingForm(BuildContext context, String location) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Booking Form'),
          content: BookingForm(location: location),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _showReservationConfirmation(context, location);
              },
              child: const Text('Book'),
            ),
          ],
        );
      },
    );
  }
 
  void _showReservationConfirmation(BuildContext context, String location) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Reservation Confirmation'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You have successfully reserved Parking Spot $location.'),
              const SizedBox(height: 10),
              const Text('Method of Payment: Credit Card'),
              const SizedBox(height: 10),
              const Text('Car Number: ABC-123'),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
 
class ParkingCard extends StatelessWidget {
  final String location;
  final String price;
  final String hoursOfService;
  final VoidCallback onPressed;
 
  const ParkingCard({super.key, 
    required this.location,
    required this.price,
    required this.hoursOfService,
    required this.onPressed,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hoursOfService,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Center(
                child: CupertinoButton(
                  onPressed: onPressed,
                  color: Colors.blue,
                  child: const Text('Book', 
                  style: TextStyle(
                  color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
class BookingForm extends StatefulWidget {
  final String location;
 
  const BookingForm({super.key, required this.location});
 
  @override
  _BookingFormState createState() => _BookingFormState();
}
 
class _BookingFormState extends State<BookingForm> {
  bool sameAddressChecked = true;
  bool differentAddressChecked = false;
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location: ${widget.location}'),
        const SizedBox(height: 10),
        const Text('Enter Payment Details:'),
        const CupertinoTextField(
          placeholder: 'Cardholder Name',
        ),
        const CupertinoTextField(
          placeholder: 'Card Number',
        ),
        const CupertinoTextField(
          placeholder: 'Expiration Date',
        ),
        const CupertinoTextField(
          placeholder: 'CVC',
        ),
        const SizedBox(height: 10),
        const Text('Billing Address:'),
        CupertinoTextField(
          placeholder: 'Address',
          enabled: !sameAddressChecked,
        ),
        CupertinoTextField(
          placeholder: 'City',
          enabled: !sameAddressChecked,
        ),
        CupertinoTextField(
          placeholder: 'State',
          enabled: !sameAddressChecked,
        ),
        CupertinoTextField(
          placeholder: 'Zip Code',
          enabled: !sameAddressChecked,
        ),
        const SizedBox(height: 10),
        const Text('Select Form of Payment:'),
        Row(
          children: [
            CupertinoCheckbox(
              value: sameAddressChecked,
              onChanged: (value) {
                setState(() {
                  sameAddressChecked = value ?? false;
                  if (sameAddressChecked) {
                    differentAddressChecked = false;
                  }
                });
              },
            ),
            const Text('Same as Shipping Address'),
          ],
        ),
        Row(
          children: [
            CupertinoCheckbox(
              value: differentAddressChecked,
              onChanged: (value) {
                setState(() {
                  differentAddressChecked = value ?? false;
                  if (differentAddressChecked) {
                    sameAddressChecked = false;
                  }
                });
              },
            ),
            const Text('Use a Different Billing Address'),
          ],
        ),
      ],
    );
  }
}