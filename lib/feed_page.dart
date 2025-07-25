import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';

class FeedPage extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> getPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feed"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(post['content'] ?? ''),
                  leading: post['imageUrl'] != null ? Image.network(post['imageUrl'], width: 50) : null,
                  subtitle: Text(post['timestamp'].toDate().toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // implement post creation
        },
      ),
    );
  }
}
