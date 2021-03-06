import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
   String postOrientation ='grid';
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  int postCount = 0;
  List<Post> posts = [];
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkFollowing();
  }
  checkFollowing()async{
    DocumentSnapshot doc = await followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .get();
      setState(() {
        isFollowing = doc.exists;
      });
  }
  
  getFollowers() async {
 QuerySnapshot snapshot = await followersRef
    .document(widget.profileId)
    .collection('userFollowers')
    .getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
 QuerySnapshot snapshot = await followingRef
    .document(widget.profileId)
    .collection('userFollowing')
    .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc:doc,isPage: false,)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color:isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    }
    else if(isFollowing) {
       return buildButton(text: "Unfollow", function: handleUnfollow);
    } else if(!isFollowing) {
     return buildButton(text: "follow", function: handleFollow);   
    }
  }

handleUnfollow(){
setState(() {
  isFollowing =false;
});
followersRef
  .document(widget.profileId)
  .collection('userFollowers')
  .document(currentUserId)
  .get().then((doc){
    if(doc.exists){
      doc.reference.delete();
    }
  });

followingRef
  .document(currentUserId)
  .collection('userFollowing')
  .document(widget.profileId)
  .get().then((doc){
    if(doc.exists){
    doc.reference.delete();
    }
  });

activityFeedRef
  .document(widget.profileId)
  .collection('feedItems')
  .document(currentUserId)
  .get().then((doc){
    if(doc.exists){
    doc.reference.delete();
    }
  });
}

handleFollow(){
setState(() {
  isFollowing =true;
});
followersRef
  .document(widget.profileId)
  .collection('userFollowers')
  .document(currentUserId)
  .setData({});

followingRef
  .document(currentUserId)
  .collection('userFollowing')
  .document(widget.profileId)
  .setData({});

activityFeedRef
  .document(widget.profileId)
  .collection('feedItems')
  .document(currentUserId)
  .setData({
    "type":"follow",
    'ownerId':widget.profileId,
    "username":currentUser.username,
    'userId':currentUserId,
    'userProfileImg':currentUser.photourl,
    'timestamp':timestamp
  });
}
  buildProfileHeader() {
 
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user =  User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photourl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } 
    
    else if(postCount==0){

    return  Container(
      color:Colors.white,
      child: Column(
        
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/no_content.svg', height: 260.0,),
          Padding(padding: EdgeInsets.only(top:10),),
        Align(
         child: Text('No Posts',
         style: TextStyle(fontSize: 30,
         color:Colors.redAccent
         ),
         ),
         alignment:Alignment(0, -1)
        )
        ],
      ),
    );
    }
    else if(postOrientation=='grid') {
      List<GridTile> gridTiles = [];
    posts.forEach((post) {
      gridTiles.add(GridTile(child: PostTile(post)));
    });
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.0,
      mainAxisSpacing: 1.5,
      crossAxisSpacing: 1.5,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: gridTiles,
    );

    }
    else if(postOrientation=='list'){
      return Column(

      children: posts,
    );
    }
    
  }
buildTogglePostOrientation(){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      IconButton(
        icon: Icon(Icons.grid_on),
        color:postOrientation=='grid'?Theme.of(context).primaryColor:Colors.grey,
        onPressed: (){
          setState(() {
            postOrientation='grid';
          });
        },
      ),
       IconButton(
        icon: Icon(Icons.list),
        color:postOrientation=='list'?Theme.of(context).primaryColor:Colors.grey,
        onPressed: (){
          setState(() {
            postOrientation='list';
          });
        }
      )
  ],);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Profile",isTitle: true),
      body: ListView(
        
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildTogglePostOrientation(),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
