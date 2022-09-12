import 'dart:ui';

void drawCorrect(Canvas canvas, double width, double height, double top,
    double left, Color color) {
  Path path_0 = Path();
  path_0.moveTo(left + width * 0.3483398, top + height * 0.7034180);
  path_0.cubicTo(
      left + width * 0.3358398,
      top + height * 0.6885742,
      left + width * 0.3377930,
      top + height * 0.6664062,
      left + width * 0.3526367,
      top + height * 0.6539062);
  path_0.lineTo(left + width * 0.7834961, top + height * 0.2923828);
  path_0.cubicTo(
      left + width * 0.7983398,
      top + height * 0.2798828,
      left + width * 0.8205078,
      top + height * 0.2818359,
      left + width * 0.8330078,
      top + height * 0.2966797);
  path_0.cubicTo(
      left + width * 0.8455078,
      top + height * 0.3115234,
      left + width * 0.8435547,
      top + height * 0.3336914,
      left + width * 0.8287109,
      top + height * 0.3461914);
  path_0.lineTo(left + width * 0.3978516, top + height * 0.7077148);
  path_0.cubicTo(
      left + width * 0.3830078,
      top + height * 0.7202148,
      left + width * 0.3608398,
      top + height * 0.7182617,
      left + width * 0.3483398,
      top + height * 0.7034180);
  path_0.close();

  Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
  paint_0_fill.color = color;
  canvas.drawPath(path_0, paint_0_fill);

  Path path_1 = Path();
  path_1.moveTo(left + width * 0.3971680, top + height * 0.7077148);
  path_1.cubicTo(
      left + width * 0.3823242,
      top + height * 0.7202148,
      left + width * 0.3601563,
      top + height * 0.7182617,
      left + width * 0.3476563,
      top + height * 0.7034180);
  path_1.lineTo(left + width * 0.1668945, top + height * 0.4878906);
  path_1.cubicTo(
      left + width * 0.1543945,
      top + height * 0.4730469,
      left + width * 0.1563477,
      top + height * 0.4508789,
      left + width * 0.1711914,
      top + height * 0.4383789);
  path_1.cubicTo(
      left + width * 0.1860352,
      top + height * 0.4258789,
      left + width * 0.2082031,
      top + height * 0.4278320,
      left + width * 0.2207031,
      top + height * 0.4426758);
  path_1.lineTo(left + width * 0.4015625, top + height * 0.6582031);
  path_1.cubicTo(
      left + width * 0.4139648,
      top + height * 0.6730469,
      left + width * 0.4121094,
      top + height * 0.6952148,
      left + width * 0.3971680,
      top + height * 0.7077148);
  path_1.close();

  Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
  paint_1_fill.color = color;
  canvas.drawPath(path_1, paint_1_fill);
}

void drawHalfCorrect(Canvas canvas, double width, double height, double top,
    double left, Color color) {
  Path path_0 = Path();
  path_0.moveTo(left + width * 0.8430664, top + height * 0.2890625);
  path_0.cubicTo(
      left + width * 0.8305664,
      top + height * 0.2742188,
      left + width * 0.8083984,
      top + height * 0.2722656,
      left + width * 0.7935547,
      top + height * 0.2847656);
  path_0.lineTo(left + width * 0.6094727, top + height * 0.4391602);
  path_0.lineTo(left + width * 0.5462891, top + height * 0.3638672);
  path_0.cubicTo(
      left + width * 0.5337891,
      top + height * 0.3490234,
      left + width * 0.5116211,
      top + height * 0.3470703,
      left + width * 0.4967773,
      top + height * 0.3595703);
  path_0.cubicTo(
      left + width * 0.4819336,
      top + height * 0.3720703,
      left + width * 0.4799805,
      top + height * 0.3942383,
      left + width * 0.4924805,
      top + height * 0.4090820);
  path_0.lineTo(left + width * 0.5556641, top + height * 0.4843750);
  path_0.lineTo(left + width * 0.3701172, top + height * 0.6400391);
  path_0.lineTo(left + width * 0.2108398, top + height * 0.4502930);
  path_0.cubicTo(
      left + width * 0.1983398,
      top + height * 0.4354492,
      left + width * 0.1761719,
      top + height * 0.4334961,
      left + width * 0.1613281,
      top + height * 0.4459961);
  path_0.cubicTo(
      left + width * 0.1464844,
      top + height * 0.4584961,
      left + width * 0.1445313,
      top + height * 0.4806641,
      left + width * 0.1570312,
      top + height * 0.4955078);
  path_0.lineTo(left + width * 0.3377930, top + height * 0.7109375);
  path_0.cubicTo(
      left + width * 0.3450195,
      top + height * 0.7195312,
      left + width * 0.3554688,
      top + height * 0.7238281,
      left + width * 0.3659180,
      top + height * 0.7234375);
  path_0.cubicTo(
      left + width * 0.3743164,
      top + height * 0.7237305,
      left + width * 0.3829102,
      top + height * 0.7210937,
      left + width * 0.3899414,
      top + height * 0.7152344);
  path_0.lineTo(left + width * 0.6008789, top + height * 0.5381836);
  path_0.lineTo(left + width * 0.6732422, top + height * 0.6244141);
  path_0.cubicTo(
      left + width * 0.6857422,
      top + height * 0.6392578,
      left + width * 0.7079102,
      top + height * 0.6412109,
      left + width * 0.7227539,
      top + height * 0.6287109);
  path_0.cubicTo(
      left + width * 0.7375977,
      top + height * 0.6162109,
      left + width * 0.7395508,
      top + height * 0.5940430,
      left + width * 0.7270508,
      top + height * 0.5791992);
  path_0.lineTo(left + width * 0.6546875, top + height * 0.4929687);
  path_0.lineTo(left + width * 0.8386719, top + height * 0.3385742);
  path_0.cubicTo(
      left + width * 0.8535156,
      top + height * 0.3261719,
      left + width * 0.8554688,
      top + height * 0.3040039,
      left + width * 0.8430664,
      top + height * 0.2890625);
  path_0.close();

  Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
  paint_0_fill.color = color;
  canvas.drawPath(path_0, paint_0_fill);
}

void drawWrong(Canvas canvas, double width, double height, double top,
    double left, Color color) {
  Path path_0 = Path();
  path_0.moveTo(left + width * 0.7761719, top + height * 0.7761719);
  path_0.cubicTo(
      left + width * 0.7625000,
      top + height * 0.7898437,
      left + width * 0.7401367,
      top + height * 0.7898437,
      left + width * 0.7264648,
      top + height * 0.7761719);
  path_0.lineTo(left + width * 0.2238281, top + height * 0.2735352);
  path_0.cubicTo(
      left + width * 0.2101562,
      top + height * 0.2598633,
      left + width * 0.2101562,
      top + height * 0.2375000,
      left + width * 0.2238281,
      top + height * 0.2238281);
  path_0.cubicTo(
      left + width * 0.2375000,
      top + height * 0.2101563,
      left + width * 0.2598633,
      top + height * 0.2101563,
      left + width * 0.2735352,
      top + height * 0.2238281);
  path_0.lineTo(left + width * 0.7762695, top + height * 0.7265625);
  path_0.cubicTo(
      left + width * 0.7898437,
      top + height * 0.7401367,
      left + width * 0.7898437,
      top + height * 0.7625000,
      left + width * 0.7761719,
      top + height * 0.7761719);
  path_0.close();

  Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
  paint_0_fill.color = color;
  canvas.drawPath(path_0, paint_0_fill);

  Path path_1 = Path();
  path_1.moveTo(left + width * 0.7761719, top + height * 0.2238281);
  path_1.cubicTo(
      left + width * 0.7898437,
      top + height * 0.2375000,
      left + width * 0.7898437,
      top + height * 0.2598633,
      left + width * 0.7761719,
      top + height * 0.2735352);
  path_1.lineTo(left + width * 0.2735352, top + height * 0.7761719);
  path_1.cubicTo(
      left + width * 0.2598633,
      top + height * 0.7898437,
      left + width * 0.2375000,
      top + height * 0.7898437,
      left + width * 0.2238281,
      top + height * 0.7761719);
  path_1.cubicTo(
      left + width * 0.2101563,
      top + height * 0.7625000,
      left + width * 0.2101563,
      top + height * 0.7401367,
      left + width * 0.2238281,
      top + height * 0.7264648);
  path_1.lineTo(left + width * 0.7265625, top + height * 0.2237305);
  path_1.cubicTo(
      left + width * 0.7401367,
      top + height * 0.2101562,
      left + width * 0.7625000,
      top + height * 0.2101562,
      left + width * 0.7761719,
      top + height * 0.2238281);
  path_1.close();

  Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
  paint_1_fill.color = color;
  canvas.drawPath(path_1, paint_1_fill);
}
