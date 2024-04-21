import "package:flutter/material.dart";

class rows_col extends StatelessWidget {
  const rows_col({super.key});

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text(
            'Rows and cols',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        body: Container(
          height: h,
          width: w,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 5; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      color: Colors.yellow,
                    ),
                    Container(
                      height: 50,
                      width: 50,
                      color: Colors.orange,
                    ),
                    Container(
                      height: 50,
                      width: 50,
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),
        ));
  }
}
