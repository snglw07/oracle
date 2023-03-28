import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:wbyq/res/res_index.dart';

class TextStyles {
  static TextStyle listTitle =
      TextStyle(fontSize: Dimens.font_sp16, color: Colours.text_dark);
  static TextStyle listTitleGreen = TextStyle(
      fontSize: Dimens.font_sp16, color: Colors.green.withOpacity(0.8));
  static TextStyle listTitleRed =
      TextStyle(fontSize: Dimens.font_sp16, color: Colors.red.withOpacity(0.8));
  static TextStyle listContent =
      TextStyle(fontSize: Dimens.font_sp14, color: Colours.text_normal);
  static TextStyle listExtra =
      TextStyle(fontSize: Dimens.font_sp12, color: Colours.text_gray);
  static TextStyle listF12Grey =
      TextStyle(fontSize: Dimens.font_sp12, color: Colors.grey);
  static TextStyle listF12GreyB = TextStyle(
      fontSize: Dimens.font_sp12,
      color: Colors.grey,
      fontWeight: FontWeight.bold);
  static TextStyle listF13Grey = TextStyle(fontSize: 13, color: Colors.grey);
  static TextStyle listF13Green = TextStyle(fontSize: 13, color: Colors.green);
  static TextStyle listF13GreyB =
      TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold);
  static TextStyle listHeader15 = TextStyle(fontSize: 15, color: Colors.black);
  static TextStyle listBlack13 = TextStyle(fontSize: 13, color: Colors.black);
  static TextStyle listContenntHui =
      TextStyle(fontSize: Dimens.font_sp14, color: Colors.grey);
  static TextStyle listTitleBig =
      TextStyle(fontSize: Dimens.font_sp18, color: Colours.text_dark);
  static TextStyle listTitleBigBold = TextStyle(
      fontSize: Dimens.font_sp18,
      color: Colours.text_dark,
      fontWeight: FontWeight.bold);
}

class Decorations {
  static Decoration bottom =
      BoxDecoration(border: Border(bottom: BorderSides.grey300w05));

  static Decoration top =
      BoxDecoration(border: Border(top: BorderSides.grey300w05));

  static Decoration bottom2 =
      BoxDecoration(border: Border(bottom: BorderSides.grey300w2));

  static Decoration bottom4 =
      BoxDecoration(border: Border(bottom: BorderSides.grey300w4));

  static Decoration bottom8 =
      BoxDecoration(border: Border(bottom: BorderSides.grey300w8));

  static Decoration bottom10 =
      BoxDecoration(border: Border(bottom: BorderSides.grey300w10));

  static Decoration top2 =
      BoxDecoration(border: Border(top: BorderSides.grey300w2));

  static Decoration top4 =
      BoxDecoration(border: Border(top: BorderSides.grey300w4));

  static Decoration top8 =
      BoxDecoration(border: Border(top: BorderSides.grey300w8));

  static Decoration top10 =
      BoxDecoration(border: Border(top: BorderSides.grey300w10));

  static Decoration topbottom8 = BoxDecoration(
      border:
          Border(top: BorderSides.grey300w10, bottom: BorderSides.grey300w10));

  static Decoration topbottom10 = BoxDecoration(
      border:
          Border(top: BorderSides.grey300w10, bottom: BorderSides.grey300w10));

  static Decoration chatInputOutDec = BoxDecoration(
      border:
          Border(top: BorderSides.grey300w05, bottom: BorderSides.grey300w05),
      color: Colors.grey.withOpacity(0.2));

  static Decoration chatInputDec = BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(5));
}

/// 间隔
class Gaps {
  /// 水平间隔
  static Widget hGap5 = SizedBox(width: Dimens.gap_dp5);
  static Widget hGap10 = SizedBox(width: Dimens.gap_dp10);
  static Widget hGap15 = SizedBox(width: Dimens.gap_dp15);

  /// 垂直间隔
  static Widget vGap5 = SizedBox(height: Dimens.gap_dp5);
  static Widget vGap10 = SizedBox(height: Dimens.gap_dp10);
  static Widget vGap15 = SizedBox(height: Dimens.gap_dp15);
}

class BorderSides {
  static BorderSide grey300w05 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 0.5);
  static BorderSide grey300w1 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 1.0);
  static BorderSide grey300w2 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 2.0);
  static BorderSide grey300w4 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 4.0);
  static BorderSide grey300w5 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 5.0);
  static BorderSide grey300w8 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 8.0);
  static BorderSide grey300w10 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 10.0);
  static BorderSide grey300w15 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 15.0);
  static BorderSide grey300w20 = BorderSide(
      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green, width: 20.0);
}
