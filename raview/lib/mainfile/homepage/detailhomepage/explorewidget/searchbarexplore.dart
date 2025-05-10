import 'package:flutter/material.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';

class SearchBarAndFilter extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const SearchBarAndFilter({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 27, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 7,
                    spreadRadius: 3,
                    color: context.isDarkMode
                        ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3)
                        : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 30, color: Colors.black,),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kemana nih?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextField(
                            controller: controller,
                            onChanged: onChanged,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Jarak . Rating",
                              hintStyle: TextStyle(
                                color: Colors.black38,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                  BoxShadow(
                    blurRadius: 7,
                    spreadRadius: 2,
                    color: context.isDarkMode
                        ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3)
                        : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                  ),
                ],
            ),
            child: Icon(Icons.tune, size: 25,color: Colors.black,),
          ),
        ],
      ),
    );
  }
}
