import 'package:flutter/cupertino.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data for achievements and rank
    List<String> achievements = [
      'Completed Level 1',
      'Reached 1000 Points',
      '10 Consecutive Days of Activity',
    ];

    int rank = 5;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/profile_picture.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'johndoe@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: EdgeInsets.symmetric(horizontal: 8.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            color: CupertinoColors.activeBlue,
                            size: 36.0,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            achievements[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Rank: #$rank',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              SizedBox(height: 20),
              CupertinoButton(
                onPressed: () {
                  // Implement edit profile functionality
                },
                child: Text('Edit Profile'),
              ),
              SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () {
                  // Implement logout functionality
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
