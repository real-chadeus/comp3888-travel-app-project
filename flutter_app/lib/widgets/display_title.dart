import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayTitleWidget extends StatelessWidget {

  final String text;
  final bool password;
  var onChanged;
  final int maxLines;
  final double height;
  final double width;
  var controller;
  DisplayTitleWidget({Key? key,this.text="input",this.password=false,required this.onChanged,this.maxLines=1,this.height=68,this.width = 700,this.controller=null}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        controller:controller,
        maxLines:this.maxLines ,
        obscureText: this.password,
        decoration: InputDecoration(
            hintText: this.text,
            hintStyle:TextStyle( color: Colors.black, fontWeight: FontWeight.bold,fontSize: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none)),
        onChanged: this.onChanged,
      ),
      height: ScreenUtil().setHeight(this.height),
      width: ScreenUtil().setWidth(this.width),

    );
  }
}
