import 'package:flutter/material.dart';
import 'package:flutter_page_indicator/flutter_page_indicator.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'config.dart';
import 'forms/form_widget.dart';

class ExampleCustom extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ExampleCustomState();
  }
}

class _ExampleCustomState extends State<ExampleCustom> {
  //properties want to custom
  int _itemCount;

  bool _loop;

  bool _autoplay;

  int _autoplayDely;

  double _padding;

  bool _outer;

  double _radius;

  double _viewportFraction;

  SwiperLayout _layout;

  int _currentIndex;

  double _scale;

  Axis _scrollDirection;

  Curve _curve;

  double _fade;

  bool _autoplayDisableOnInteraction;

  CustomLayoutOption customLayoutOption;

  Widget _buildItem(BuildContext context, int index) {
    return ClipRRect(
      borderRadius: new BorderRadius.all(new Radius.circular(_radius)),
      child: new Image.asset(
        images[index % images.length],
        fit: BoxFit.fill,
      ),
    );
  }

  @override
  void didUpdateWidget(ExampleCustom oldWidget) {
    customLayoutOption = new CustomLayoutOption(startIndex: -1, stateCount: 3)
        .addRotate([-45.0 / 180, 0.0, 45.0 / 180]).addTranslate([
      new Offset(-370.0, -40.0),
      new Offset(0.0, 0.0),
      new Offset(370.0, -40.0)
    ]);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    customLayoutOption = new CustomLayoutOption(startIndex: -1, stateCount: 3)
        .addRotate([-25.0 / 180, 0.0, 25.0 / 180]).addTranslate([
      new Offset(-350.0, 0.0),
      new Offset(0.0, 0.0),
      new Offset(350.0, 0.0)
    ]);
    _fade = 1.0;
    _currentIndex = 0;
    _curve = Curves.ease;
    _scale = 0.8;
    _controller = new SwiperController();
    _layout = SwiperLayout.TINDER;
    _radius = 10.0;
    _padding = 0.0;
    _loop = true;
    _itemCount = 3;
    _autoplay = false;
    _autoplayDely = 3000;
    _viewportFraction = 0.8;
    _outer = false;
    _scrollDirection = Axis.horizontal;
    _autoplayDisableOnInteraction = false;
    super.initState();
  }

// maintain the index

  Widget buildSwiper() {
    return new Swiper(
      onTap: (int index) {
        Navigator.of(context)
            .push(new MaterialPageRoute(builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text("New page"),
            ),
            body: Container(),
          );
        }));
      },
      customLayoutOption: customLayoutOption,
      fade: _fade,
      index: _currentIndex,
      onIndexChanged: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
      curve: _curve,
      scale: _scale,
      itemWidth: 300.0,
      controller: _controller,
      layout: _layout,
      outer: _outer,
      itemHeight: 200.0,
      viewportFraction: _viewportFraction,
      autoplayDelay: _autoplayDely,
      loop: _loop,
      autoplay: _autoplay,
      itemBuilder: _buildItem,
      itemCount: _itemCount,
      scrollDirection: _scrollDirection,
      indicatorLayout: PageIndicatorLayout.COLOR,
      autoplayDisableOnInteraction: _autoplayDisableOnInteraction,
      pagination: new SwiperPagination(
          builder: const DotSwiperPaginationBuilder(
              size: 20.0, activeSize: 20.0, space: 10.0)),
    );
  }

  SwiperController _controller;
  TextEditingController numberController = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return new Column(children: <Widget>[
      new Container(
        color: Colors.black87,
        child: new SizedBox(
            height: 300.0, width: double.infinity, child: buildSwiper()),
      ),
      new Expanded(
          child: new ListView(
        children: <Widget>[
          new Text("Index:$_currentIndex"),
          new Row(
            children: <Widget>[
              new RaisedButton(
                onPressed: () {
                  _controller.previous(animation: true);
                },
                child: new Text("Prev"),
              ),
              new RaisedButton(
                onPressed: () {
                  _controller.next(animation: true);
                },
                child: new Text("Next"),
              ),
              new Expanded(
                  child: new TextField(
                controller: numberController,
              )),
              new RaisedButton(
                onPressed: () {
                  var text = numberController.text;
                  setState(() {
                    _currentIndex = int.parse(text);
                  });
                },
                child: new Text("Update"),
              ),
            ],
          ),
          new FormWidget(
              label: "layout",
              child: new FormSelect(
                  placeholder: "Select layout",
                  value: _layout,
                  values: [
                    SwiperLayout.DEFAULT,
                    SwiperLayout.STACK,
                    SwiperLayout.TINDER,
                    SwiperLayout.CUSTOM
                  ],
                  valueChanged: (value) {
                    _layout = value;
                    setState(() {});
                  })),
          new FormWidget(
            label: "scrollDirection",
            child: new Switch(
                value: _scrollDirection == Axis.horizontal,
                onChanged: (bool value) => setState(() => _scrollDirection =
                    value ? Axis.horizontal : Axis.vertical)),
          ),
          new FormWidget(
            label: "autoplayDisableOnInteractio",
            child: new Switch(
                value: _autoplayDisableOnInteraction,
                onChanged: (bool value) =>
                    setState(() => _autoplayDisableOnInteraction = value)),
          ),
          //Pannel Begin
          new FormWidget(
            label: "loop",
            child: new Switch(
                value: _loop,
                onChanged: (bool value) => setState(() => _loop = value)),
          ),
          new FormWidget(
            label: "outer",
            child: new Switch(
                value: _outer,
                onChanged: (bool value) => setState(() => _outer = value)),
          ),
          //Pannel Begin
          new FormWidget(
            label: "autoplay",
            child: new Switch(
                value: _autoplay,
                onChanged: (bool value) => setState(() => _autoplay = value)),
          ),

          new FormWidget(
            label: "padding",
            child: new NumberPad(
              number: _padding,
              step: 5.0,
              min: 0.0,
              max: 30.0,
              onChangeValue: (num value) {
                _padding = value.toDouble();
                setState(() {});
              },
            ),
          ),
          new FormWidget(
            label: "scale",
            child: new NumberPad(
              number: _scale,
              step: 0.1,
              min: 0.0,
              max: 1.0,
              onChangeValue: (num value) {
                _scale = value.toDouble();
                setState(() {});
              },
            ),
          ),
          new FormWidget(
            label: "fade",
            child: new NumberPad(
              number: _fade,
              step: 0.1,
              min: 0.0,
              max: 1.0,
              onChangeValue: (num value) {
                _fade = value.toDouble();
                setState(() {});
              },
            ),
          ),
          new FormWidget(
            label: "itemCount",
            child: new NumberPad(
              number: _itemCount,
              step: 1,
              min: 0,
              max: 100,
              onChangeValue: (num value) {
                _itemCount = value.toInt();
                setState(() {});
              },
            ),
          ),

          new FormWidget(
            label: "radius",
            child: new NumberPad(
              number: _radius,
              step: 1.0,
              min: 0.0,
              max: 30.0,
              onChangeValue: (num value) {
                this._radius = value.toDouble();
                setState(() {});
              },
            ),
          ),

          new FormWidget(
            label: "viewportFraction",
            child: new NumberPad(
              number: _viewportFraction,
              step: 0.1,
              max: 1.0,
              min: 0.5,
              onChangeValue: (num value) {
                _viewportFraction = value.toDouble();
                setState(() {});
              },
            ),
          ),

          new FormWidget(
              label: "curve",
              child: new FormSelect(
                  placeholder: "Select curve",
                  value: _layout,
                  values: [
                    Curves.easeInOut,
                    Curves.ease,
                    Curves.bounceInOut,
                    Curves.bounceOut,
                    Curves.bounceIn,
                    Curves.fastOutSlowIn
                  ],
                  valueChanged: (value) {
                    _curve = value;
                    setState(() {});
                  })),
        ],
      ))
    ]);
  }
}
