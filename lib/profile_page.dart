import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    DocumentSnapshot userDoc =
    await firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      nameController.text = userDoc['name'];
      emailController.text = userDoc['email'];
      setState(() {
        imageUrl = userDoc['imageUrl'];
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      File file = File(picked.path);
      String path = 'profileImages/${user.uid}.jpg';
      UploadTask uploadTask =
      FirebaseStorage.instance.ref().child(path).putFile(file);

      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();

      await firestore.collection('users').doc(user.uid).update({
        'imageUrl': downloadUrl,
      });

      setState(() {
        imageUrl = downloadUrl;
      });
    }
  }

  Future<void> updateProfile() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': nameController.text,
      'email': emailController.text,
    });
  }

  Stream<QuerySnapshot> getUserPosts() {
    return firestore
        .collection('posts')
        .where('uid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null ? Icon(Icons.person, size: 50) : null,
              ),
            ),
            SizedBox(height: 10),
            Text(user.email ?? "", style: TextStyle(color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
                  TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
                  SizedBox(height: 10),
                  ElevatedButton(onPressed: updateProfile, child: Text("Update Profile")),
                ],
              ),
            ),
            Divider(),
            Text("User Posts", style: TextStyle(fontSize: 18)),
            StreamBuilder<QuerySnapshot>(
              stream: getUserPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final posts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                      child: ListTile(
                        leading: post['imageUrl'] != null
                            ? Image.network(post['imageUrl'], width: 50)
                            : null,
                        title: Text(post['content'] ?? 'No content'),
                        subtitle: Text(post['timestamp'].toDate().toString()),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}