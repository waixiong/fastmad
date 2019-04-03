import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audio_cache.dart';

Size size;
AudioCache player = new AudioCache();

var chooser = {
  's':[{'t':'START','c':4278190080}],
  'o':[{'t':'+','c':4294198070},{'t':'-','c':4294924066},{'t':'x','c':4294959104},{'t':'÷','c':4283215696}],
  'c':[{'t':'<','c':4280391411},{'t':'>','c':4282339765},{'t':'=','c':4288423856}]
};

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.light(),
    home: Game(),
  );
}

class Animate extends StatefulWidget {
  Animate(this.child, this.b, {Key key}):super(key:new UniqueKey());
  Widget child;
  double b;
  @override
  _AnimateState createState() => _AnimateState();
}

class _AnimateState extends State<Animate> with SingleTickerProviderStateMixin<Animate> {
  AnimationController controller;
  Animation<double> animate;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds:2));
    animate = CurvedAnimation(parent: controller, curve: Interval(widget.b, widget.b+0.3, curve: Curves.fastOutSlowIn));
    controller.addListener(() { setState(() {}); });
    controller.forward();
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(
    child: ScaleTransition(
      scale: animate, child: widget.child,
    ),
  );
}

class Game extends StatefulWidget {
  Game({Key key}) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  int _score = 0;
  Map q;

  @override
  void initState() {
    super.initState();
    q = question(false);
  }

  void setQ(bool t){
    setState(() { q = question(t); _score = t?_score:0; });
  }

  Widget answer(String type, BuildContext c){
    List<Widget> col = <Widget>[];
    for(int i=0;i<chooser[type].length;i+=2){
      List<Widget> row = <Widget>[];
      int rowL = chooser[type].length-i;
      for(int j=0;j<(rowL>2?2:rowL);j++){
        row.add(Expanded(child: Animate(RaisedButton(
          color: Color(chooser[type][i+j]['c']),
          onPressed: (){
            if(q['type']=='s') setQ(true);
            else{
              q[type]=chooser[type][i+j]['t'];
              if(check(q['x'], q['o'], q['y'],q['c'],q['z'])){
                int s = getMS()-q['t'];
                _score+=1000000~/(s*(s/4000));
                setQ(true); play(true);
              }else{
                play(false);
                showDialog(context: c, barrierDismissible:true, builder: (context)=>Animate(AlertDialog(
                  title: Text('Your score : $_score'), content: Text('${DateTime.now().toIso8601String()}\nBACK to restart'),
                ), 0)).then((t){ setQ(false); });
              }
            }
          },
          child: Center(child: Text(chooser[type][i+j]['t'], style: TextStyle(fontSize: 50, fontWeight: FontWeight.w600, color: Colors.white),),),
        ), 0.3+(i+j)*0.1)));
      }
      col.add(Expanded(child: Row(children: row)));
    }
    return Column(children: col);
  }

  @override
  Widget build(BuildContext c) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(q['type']=='s'?'Just solve Math!':'SCORE : $_score'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Animate(Center(
              child: Text(q['s'], textAlign:TextAlign.center, style:TextStyle(fontSize:48,fontWeight:FontWeight.w700)),
            ), 0),
          ),
          Container(
            height: size.height * 0.5,
            child: Center(
              child: answer(q['type'], c),
            ),
          )
        ],
      ),
    );
  }
}

getMS() => DateTime.now().millisecondsSinceEpoch;

Map question(bool run){
  Map<String, dynamic> q = {};
  if(!run) return {'type':'s','s':'+-<=>÷x\nFastMad'};
  var r = new Random.secure();
  q['x'] = r.nextInt(42)+9;
  q['y'] = r.nextInt(q['x']>20?20:q['x'])+1;
  int o = r.nextInt(4);
  q['o'] = o==0?'+':o==1?'-':o==2?'x':'÷';
  q['z'] = cal(q['x'],q['o'],q['y']);
  if(o==3)
    q['x'] = q['y']*q['z'];
  if(r.nextBool()){
    q['type'] = 'o';
    q['c'] = '=';
    q['o'] = '□';
  }else{
    q['type'] = 'c';
    q['c'] = '□';
    q['z'] += r.nextInt(7)-3;
  }
  q['s'] = '${q['x']} ${q['o']} ${q['y']} ${q['c']} ${q['z']}';
  q['t'] = getMS();
  return q;
}

bool check(int x, String o, int y, String c, int z){
  int a = cal(x,o,y);
  switch(c) {
    case'<':return a<z;
    case'>':return a>z;
    default:return a==z;
  }
}

int cal(int x, String o, int y){
  int a;
  if(o=='+') a=x+y;
  else if(o=='-') a=x-y;
  else if(o=='x') a=x*y;
  else a=x~/y;
  return a;
}

play(var s) => player.play('$s.mp3');