import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

  
  
  Widget StyledButton(IconData? icon, String? svgAssetPath, String label, [void Function()? delegatedOnPressed]) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 7, 0),  // Margin outside the button
      child: SizedBox(
        width: 35,  // Set button width
        height: 38,  // 
        child: ElevatedButton(
          onPressed: delegatedOnPressed ?? (){

          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(1.0),  // Padding inside the button
            backgroundColor: Colors.white,  // Button background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),  // Rounded corners
            ),
            elevation: 4,  // Add shadow for depth
          ),
          child: Column( children: [
            // Conditionally render either an Icon or SvgPicture based on the parameters
            if (icon != null) ...[ // Display Icon if IconData is passed
              Icon(icon, size: 36.0),  
            ] 
            else if (svgAssetPath != null) ...[  // Display SvgPicture if an SVG asset path is passed
              SvgPicture.asset(
                svgAssetPath,
                width: 30,
                height: 30,
              ), 
              ],
            ]
            )
        ),
      ),
    );
  }
