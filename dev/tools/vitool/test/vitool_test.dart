// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitool/vitool.dart';
import 'package:path/path.dart' as path;

const String kPackagePath = '..';

void main() {

  test('parsePixels', () {
    expect(parsePixels('23px'), 23);
    expect(parsePixels('9px'), 9);
    expect(() { parsePixels('9pt'); }, throwsA(const isInstanceOf<ArgumentError>()));
  });

  test('parsePoints', () {
    expect(parsePoints('1.0, 2.0'),
        const <Point<double>>[const Point<double>(1.0, 2.0)]
    );
    expect(parsePoints('12.0, 34.0 5.0, 6.6'),
        const <Point<double>>[
          const Point<double>(12.0, 34.0),
          const Point<double>(5.0, 6.6),
        ]
    );
    expect(parsePoints('12.0 34.0 5.0 6.6'),
        const <Point<double>>[
          const Point<double>(12.0, 34.0),
          const Point<double>(5.0, 6.6),
        ]
    );
  });

  group('parseSvg', () {
    test('empty SVGs', () {
      interpretSvg(testAsset('empty_svg_1_48x48.svg'));
      interpretSvg(testAsset('empty_svg_2_100x50.svg'));
    });

    test('illegal SVGs', () {
      expect(
        () { interpretSvg(testAsset('illegal_svg_multiple_roots.svg')); },
        throwsA(anything)
      );
    });

    test('SVG size', () {
      expect(
          interpretSvg(testAsset('empty_svg_1_48x48.svg')).size,
          const Point<double>(48.0, 48.0)
      );

      expect(
          interpretSvg(testAsset('empty_svg_2_100x50.svg')).size,
          const Point<double>(100.0, 50.0)
      );
    });

    test('horizontal bar', () {
      final FrameData frameData = interpretSvg(testAsset('horizontal_bar.svg'));
      expect(frameData.paths, <SvgPath>[
        const SvgPath('path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 29.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 29.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });

    test('leading space path command', () {
      interpretSvg(testAsset('leading_space_path_command.svg'));
    });

    test('SVG illegal path', () {
      expect(
        () { interpretSvg(testAsset('illegal_path.svg')); },
        throwsA(anything)
      );
    });


    test('SVG group', () {
      final FrameData frameData = interpretSvg(testAsset('bars_group.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath('path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 29.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 29.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
        const SvgPath('path_2', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 34.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 34.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 44.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 44.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });

    test('SVG group translate', () {
      final FrameData frameData = interpretSvg(testAsset('bar_group_translate.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath('path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 34.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 34.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 44.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 44.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });

    test('SVG group scale', () {
      final FrameData frameData = interpretSvg(testAsset('bar_group_scale.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath(
            'path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 9.5)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(24.0, 9.5)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(24.0, 14.5)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 14.5)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });

    test('SVG group rotate scale', () {
      final FrameData frameData = interpretSvg(testAsset('bar_group_rotate_scale.svg'));
      expect(frameData.paths, const <PathMatcher>[
        const PathMatcher(
            const SvgPath(
                'path_1', const<SvgPathCommand>[
              const SvgPathCommand('L', const <Point<double>>[const Point<double>(29.0, 0.0)]),
              const SvgPathCommand('L', const <Point<double>>[const Point<double>(29.0, 48.0)]),
              const SvgPathCommand('L', const <Point<double>>[const Point<double>(19.0, 48.0)]),
              const SvgPathCommand('M', const <Point<double>>[const Point<double>(19.0, 0.0)]),
              const SvgPathCommand('Z', const <Point<double>>[]),
            ]),
            margin: 0.000000001
        )
      ]);
    });

    test('SVG illegal transform', () {
      expect(
        () { interpretSvg(testAsset('illegal_transform.svg')); },
        throwsA(anything)
      );
    });

    test('SVG group opacity', () {
      final FrameData frameData = interpretSvg(testAsset('bar_group_opacity.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath(
          'path_1',
          const<SvgPathCommand>[
            const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 19.0)]),
            const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 19.0)]),
            const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 29.0)]),
            const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 29.0)]),
            const SvgPathCommand('Z', const <Point<double>>[]),
          ],
          opacity: 0.5,
        ),
      ]);
    });

    test('horizontal bar relative', () {
      // This asset uses the relative 'l' command instead of 'L'.
      final FrameData frameData = interpretSvg(testAsset('horizontal_bar_relative.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath(
            'path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 19.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(48.0, 29.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(0.0, 29.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });

    test('close in middle of path', () {
      // This asset uses the relative 'l' command instead of 'L'.
      final FrameData frameData = interpretSvg(testAsset('close_path_in_middle.svg'));
      expect(frameData.paths, const <SvgPath>[
        const SvgPath(
            'path_1', const<SvgPathCommand>[
          const SvgPathCommand('M', const <Point<double>>[const Point<double>(50.0, 50.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(60.0, 50.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(60.0, 60.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(50.0, 40.0)]),
          const SvgPathCommand('L', const <Point<double>>[const Point<double>(40.0, 40.0)]),
          const SvgPathCommand('Z', const <Point<double>>[]),
        ]),
      ]);
    });
  });

  group('create PathAnimation', () {
    test('single path', () {
      const List<FrameData> frameData = const <FrameData>[
        const FrameData(
          const Point<double>(10.0, 10.0),
          const <SvgPath>[
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 0.0)]),
                const SvgPathCommand('L', const <Point<double>>[const Point<double>(10.0, 10.0)]),
              ],
            ),
          ],
        ),
      ];
      expect(new PathAnimation.fromFrameData(frameData, 0),
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(0.0, 0.0)],
                ]),
                const PathCommandAnimation('L', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(10.0, 10.0)],
                ]),
              ],
              opacities: const <double>[1.0]
          ))
      );
    });

    test('multiple paths', () {
      const List<FrameData> frameData = const <FrameData>[
        const FrameData(
          const Point<double>(10.0, 10.0),
          const <SvgPath>[
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 0.0)]),
              ],
            ),
            const SvgPath(
              'path_2',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(5.0, 6.0)]),
              ],
            ),
          ],
        ),
      ];
      expect(new PathAnimation.fromFrameData(frameData, 0),
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(0.0, 0.0)],
                ])
              ],
              opacities: const <double>[1.0]
          ))
      );

      expect(new PathAnimation.fromFrameData(frameData, 1),
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(5.0, 6.0)],
                ])
              ],
              opacities: const <double>[1.0]
          ))
      );
    });

    test('multiple frames', () {
      const List<FrameData> frameData = const <FrameData>[
        const FrameData(
          const Point<double>(10.0, 10.0),
          const <SvgPath>[
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 0.0)])
              ],
              opacity: 0.5,
            ),
          ],
        ),
        const FrameData(
          const Point<double>(10.0, 10.0),
          const <SvgPath>[
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(10.0, 10.0)])
              ],
            ),
          ],
        ),
      ];
      expect(new PathAnimation.fromFrameData(frameData, 0),
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[
                    const Point<double>(0.0, 0.0),
                    const Point<double>(10.0, 10.0),
                  ],
                ]),
              ],
              opacities: const <double>[0.5, 1.0]
          ))
      );
    });
  });

  group('create Animation', () {
    test('multiple paths', () {
      const List<FrameData> frameData = const <FrameData>[
        const FrameData(
          const Point<double>(10.0, 10.0),
          const <SvgPath>[
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(0.0, 0.0)]),
              ],
            ),
            const SvgPath(
              'path_1',
              const <SvgPathCommand>[
                const SvgPathCommand('M', const <Point<double>>[const Point<double>(5.0, 6.0)]),
              ],
            ),
          ],
        ),
      ];
      final Animation animation = new Animation.fromFrameData(frameData);
      expect(animation.paths[0],
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(0.0, 0.0)],
                ])
              ],
              opacities: const <double>[1.0]
          ))
      );

      expect(animation.paths[1],
          const PathAnimationMatcher(const PathAnimation(
              const <PathCommandAnimation>[
                const PathCommandAnimation('M', const <List<Point<double>>>[
                  const <Point<double>>[const Point<double>(5.0, 6.0)],
                ])
              ],
              opacities: const <double>[1.0]
          ))
      );

      expect(animation.size, const Point<double>(10.0, 10.0));
    });
  });

  group('toDart', () {
    test('_PathMoveTo', () {
      const PathCommandAnimation command = const PathCommandAnimation(
        'M',
        const <List<Point<double>>>[
          const <Point<double>>[
            const Point<double>(1.0, 2.0),
            const Point<double>(3.0, 4.0),
          ],
        ],
      );

      expect(command.toDart(),
          '        const _PathMoveTo(\n'
          '          const <Offset>[\n'
          '            const Offset(1.0, 2.0),\n'
          '            const Offset(3.0, 4.0),\n'
          '          ],\n'
          '        ),\n'

      );
    });

    test('_PathLineTo', () {
      const PathCommandAnimation command = const PathCommandAnimation(
        'L',
        const <List<Point<double>>>[
          const <Point<double>>[
            const Point<double>(1.0, 2.0),
            const Point<double>(3.0, 4.0),
          ],
        ],
      );

      expect(command.toDart(),
          '        const _PathLineTo(\n'
          '          const <Offset>[\n'
          '            const Offset(1.0, 2.0),\n'
          '            const Offset(3.0, 4.0),\n'
          '          ],\n'
          '        ),\n'

      );
    });

    test('_PathCubicTo', () {
      const PathCommandAnimation command = const PathCommandAnimation(
        'C',
        const <List<Point<double>>>[
          const <Point<double>>[
            const Point<double>(16.0, 24.0),
            const Point<double>(16.0, 10.0),
          ],
          const <Point<double>>[
            const Point<double>(16.0, 25.0),
            const Point<double>(16.0, 11.0),
          ],
          const <Point<double>>[
            const Point<double>(40.0, 40.0),
            const Point<double>(40.0, 40.0),
          ],
        ],
      );

      expect(command.toDart(),
          '        const _PathCubicTo(\n'
          '          const <Offset>[\n'
          '            const Offset(16.0, 24.0),\n'
          '            const Offset(16.0, 10.0),\n'
          '          ],\n'
          '          const <Offset>[\n'
          '            const Offset(16.0, 25.0),\n'
          '            const Offset(16.0, 11.0),\n'
          '          ],\n'
          '          const <Offset>[\n'
          '            const Offset(40.0, 40.0),\n'
          '            const Offset(40.0, 40.0),\n'
          '          ],\n'
          '        ),\n'

      );
    });

    test('_PathClose', () {
      const PathCommandAnimation command = const PathCommandAnimation(
        'Z',
        const <List<Point<double>>>[],
      );

      expect(command.toDart(),
          '        const _PathClose(\n'
          '        ),\n'

      );
    });

    test('Unsupported path command', () {
      const PathCommandAnimation command = const PathCommandAnimation(
        'h',
        const <List<Point<double>>>[],
      );

      expect(
        () { command.toDart(); },
        throwsA(anything)
      );
    });

    test('_PathFrames', () {
      const PathAnimation pathAnimation = const PathAnimation(
          const <PathCommandAnimation>[
            const PathCommandAnimation('M', const <List<Point<double>>>[
              const <Point<double>>[
                const Point<double>(0.0, 0.0),
                const Point<double>(10.0, 10.0),
              ],
            ]),
            const PathCommandAnimation('L', const <List<Point<double>>>[
              const <Point<double>>[
                const Point<double>(48.0, 10.0),
                const Point<double>(0.0, 0.0),
              ],
            ]),
          ],
          opacities: const <double>[0.5, 1.0]
      );

      expect(pathAnimation.toDart(),
          '    const _PathFrames(\n'
          '      opacities: const <double>[\n'
          '        0.5,\n'
          '        1.0,\n'
          '      ],\n'
          '      commands: const <_PathCommand>[\n'
          '        const _PathMoveTo(\n'
          '          const <Offset>[\n'
          '            const Offset(0.0, 0.0),\n'
          '            const Offset(10.0, 10.0),\n'
          '          ],\n'
          '        ),\n'
          '        const _PathLineTo(\n'
          '          const <Offset>[\n'
          '            const Offset(48.0, 10.0),\n'
          '            const Offset(0.0, 0.0),\n'
          '          ],\n'
          '        ),\n'
          '      ],\n'
          '    ),\n'
      );
    });

    test('Animation', () {
      const Animation animation = const Animation(
          const Point<double>(48.0, 48.0),
          const <PathAnimation>[
            const PathAnimation(
                const <PathCommandAnimation>[
                  const PathCommandAnimation('M', const <List<Point<double>>>[
                    const <Point<double>>[
                      const Point<double>(0.0, 0.0),
                      const Point<double>(10.0, 10.0),
                    ],
                  ]),
                  const PathCommandAnimation('L', const <List<Point<double>>>[
                    const <Point<double>>[
                      const Point<double>(48.0, 10.0),
                      const Point<double>(0.0, 0.0),
                    ],
                  ]),
                ],
                opacities: const <double>[0.5, 1.0]
            ),

            const PathAnimation(
                const <PathCommandAnimation>[
                  const PathCommandAnimation('M', const <List<Point<double>>>[
                    const <Point<double>>[
                      const Point<double>(0.0, 0.0),
                      const Point<double>(10.0, 10.0),
                    ],
                  ]),
                ],
                opacities: const <double>[0.5, 1.0]
            ),
          ]);

      expect(animation.toDart('_AnimatedIconData', '_\$data1'),
          'const _AnimatedIconData _\$data1 = const _AnimatedIconData(\n'
          '  const Size(48.0, 48.0),\n'
          '  const <_PathFrames>[\n'
          '    const _PathFrames(\n'
          '      opacities: const <double>[\n'
          '        0.5,\n'
          '        1.0,\n'
          '      ],\n'
          '      commands: const <_PathCommand>[\n'
          '        const _PathMoveTo(\n'
          '          const <Offset>[\n'
          '            const Offset(0.0, 0.0),\n'
          '            const Offset(10.0, 10.0),\n'
          '          ],\n'
          '        ),\n'
          '        const _PathLineTo(\n'
          '          const <Offset>[\n'
          '            const Offset(48.0, 10.0),\n'
          '            const Offset(0.0, 0.0),\n'
          '          ],\n'
          '        ),\n'
          '      ],\n'
          '    ),\n'
          '    const _PathFrames(\n'
          '      opacities: const <double>[\n'
          '        0.5,\n'
          '        1.0,\n'
          '      ],\n'
          '      commands: const <_PathCommand>[\n'
          '        const _PathMoveTo(\n'
          '          const <Offset>[\n'
          '            const Offset(0.0, 0.0),\n'
          '            const Offset(10.0, 10.0),\n'
          '          ],\n'
          '        ),\n'
          '      ],\n'
          '    ),\n'
          '  ],\n'
          ');'
      );
    });
  });
}

// Matches all path commands' points within an error margin.
class PathMatcher extends Matcher {
  const PathMatcher(this.actual, {this.margin = 0.0});

  final SvgPath actual;
  final double margin;

  @override
  Description describe(Description description) => description.add('$actual (±$margin)');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item == null || actual == null)
      return item == actual;

    if (item.runtimeType != actual.runtimeType)
      return false;

    final SvgPath other = item;
    if (other.id != actual.id || other.opacity != actual.opacity)
      return false;

    if (other.commands.length != actual.commands.length)
      return false;

    for (int i = 0; i < other.commands.length; i += 1) {
      if (!commandsMatch(actual.commands[i], other.commands[i]))
        return false;
    }
    return true;
  }

  bool commandsMatch(SvgPathCommand actual, SvgPathCommand other) {
    if (other.points.length != actual.points.length)
      return false;

    for (int i = 0; i < other.points.length; i += 1) {
      if ((other.points[i].x - actual.points[i].x).abs() > margin)
        return false;
      if ((other.points[i].y - actual.points[i].y).abs() > margin)
        return false;
    }
    return true;
  }
}

class PathAnimationMatcher extends Matcher {
  const PathAnimationMatcher(this.expected);

  final PathAnimation expected;

  @override
  Description describe(Description description) => description.add('$expected');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item == null || expected == null)
      return item == expected;

    if (item.runtimeType != expected.runtimeType)
      return false;

    final PathAnimation other = item;

    if (!const ListEquality<double>().equals(other.opacities, expected.opacities))
      return false;

    if (other.commands.length != expected.commands.length)
      return false;

    for (int i = 0; i < other.commands.length; i += 1) {
      if (!commandsMatch(expected.commands[i], other.commands[i]))
        return false;
    }
    return true;
  }

  bool commandsMatch(PathCommandAnimation expected, PathCommandAnimation other) {
    if (other.points.length != expected.points.length)
      return false;

    for (int i = 0; i < other.points.length; i += 1)
      if (!const ListEquality<Point<double>>().equals(other.points[i], expected.points[i]))
        return false;

    return true;
  }
}

String testAsset(String name) {
  return path.join(kPackagePath, 'test_assets', name);
}

