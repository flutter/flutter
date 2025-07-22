'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.js": "ede049bc1ed3a36d9fff776ee552e414",
"canvaskit/skwasm.js.symbols": "aaac3a3efacad2638f920cc6e3a7a937",
"canvaskit/canvaskit.js.symbols": "fdb96bd379161eeca8efe43d55391511",
"canvaskit/chromium/canvaskit.js.symbols": "dffc307c6659861cf397666019b49e54",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "4d24e294fb3e57c24ed3f695e4fb0d93",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "c762ce05acbce01fceaabef602da5149",
"canvaskit/skwasm.wasm": "36d9599542735a1a9c20eb68a71671a5",
"manifest.json": "9f2208d3303a34594e332da25d9132e6",
"main.dart.wasm.map": "998dd2335b9d6d06c75d854259cf08c7",
"assets/AssetManifest.bin": "b3c07743f7d53ce13748997c212ae962",
"assets/NOTICES": "26ee299e8f991650f906ac678bc1badf",
"assets/icons/phone@2x.png": "19a0c9d18f17958c7cd847915936642b",
"assets/icons/debug_banner.png": "f0669ee6cfba83e137744025addd2e3b",
"assets/icons/app_bar/deep_links.png": "0cfa72ff440522c8cfb7c1df1e9cb58e",
"assets/icons/app_bar/devtools.png": "963c47ce0e58401ca25830242603d09b",
"assets/icons/app_bar/logging.png": "9f75504bb7bfe05d10f4b30c7cb0b2b6",
"assets/icons/app_bar/network.png": "b3d3d9533cc45d493637c07333aadd85",
"assets/icons/app_bar/app_size.png": "a4dbac633bce411b03e68d8335165790",
"assets/icons/app_bar/devtools_extensions.png": "58043cbf429e1610db137424754d3f70",
"assets/icons/app_bar/inspector.png": "6e5a856cbb21c1ee07e3a5342071970d",
"assets/icons/app_bar/performance.png": "8169861f18ae67f97c2e7bff6ccd5dd6",
"assets/icons/app_bar/cpu_profiler.png": "a42d6b8db7b7034b8e9537cb6bd1b7b3",
"assets/icons/app_bar/memory.png": "041016ae5f4e9753132ac893aba57a58",
"assets/icons/performance-dgrey.png": "2422381695e723a6db65bbf6c5f4f3d0",
"assets/icons/feedback.png": "7646ea4d8b319023ff9821e4b5228716",
"assets/icons/slow-white.png": "ccd9b3acca53f15c4429ec1ae7b95b08",
"assets/icons/template_new_project.png": "8839e9568fe27dd8763f65827279646c",
"assets/icons/flutter_13.png": "c76a0e121afbba68061ce1bfe2f369a2",
"assets/icons/cancel@2x.png": "c509b4ad1eebf5ef952a56c2e1abdb12",
"assets/icons/flutter_13@2x.png": "f2e619b6ca36e53951d6be3b850e60fc",
"assets/icons/trackwidget-white.png": "e440b99af68f6c8eb28f23104be807a7",
"assets/icons/memory_dashboard.png": "0a2bfd9286470d3edc303dc1f5955088",
"assets/icons/reload_debug.png": "25174df7af338a404352a6c3ef3db4a9",
"assets/icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"assets/icons/flutter.png": "6a8302a74f9a3ed272937486f921026e",
"assets/icons/template_new_package.png": "0557aa1c93139137ad85f22fe2758a2a",
"assets/icons/observatory_overflow.png": "94a85472af26fe159772b52fbd232b71",
"assets/icons/attachDebugger@2x.png": "c6b48f1a6edf49d444fad893653cde62",
"assets/icons/performance-white.png": "50cbda1fb3325007cfd656306472d92f",
"assets/icons/hot-restart-white.png": "cc04e9b639bb44cd128d6d313c39283d",
"assets/icons/actions/forceRefresh.png": "8a3f17c81bc6719dca319d40e5041274",
"assets/icons/actions/forceRefresh@2x.png": "8a3f17c81bc6719dca319d40e5041274",
"assets/icons/actions/forceRefresh_dark.svg": "788520d88103c871f95bfe8e65980564",
"assets/icons/gutter/colors.png": "51d32728d990baf55d1c8603118d6262",
"assets/icons/gutter/colors@2x.png": "776e366471592ddb63fe5fc594a39e5c",
"assets/icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"assets/icons/widget-select-dgrey.png": "ea81d887d5177b2b9fca6f4474a1bed6",
"assets/icons/cancel.png": "8bb2114c6c2203f0cbd4aa45a62672dc",
"assets/icons/flutter@2x.png": "d279eea967055d8bcaafcecc96b9ea44",
"assets/icons/bazel_run@2x.png": "b1a914fbcf48bc4e0d3b35d95e3ee287",
"assets/icons/baselines-dgrey.png": "86d010c6d4be71c09972ad913b270094",
"assets/icons/hot-reload@2x.png": "994ce33f77d7673e0c2b6f40013a4510",
"assets/icons/refresh-dgrey.png": "0c9875bce5f8417a1cc56954c54ffd04",
"assets/icons/template_new_module.png": "cf79c79f983e0237d72d41f597e7b5b8",
"assets/icons/observatory.png": "5cba4b21e3c417a1bf6fdbe66dd1cae6",
"assets/icons/template_new_plugin.png": "a94257e34875df546fb19e089ce721b1",
"assets/icons/hot-restart.png": "b7527e2a55e166ac5d2cda4c8a7cda1a",
"assets/icons/material_symbols/resume.png": "02fba2cf75ce7ead00a19a6b8f492138",
"assets/icons/material_symbols/step_out.png": "93e107b7eca239eeda7d11e91d16d127",
"assets/icons/material_symbols/step_into.png": "8677eb90cebf72c7369341366b8d7619",
"assets/icons/material_symbols/step_over.png": "8ded34d37121ec36738a7157f7123e6a",
"assets/icons/material_symbols/LICENSE": "ad4caa1a11d0b4f4ec1390fb77a33cc4",
"assets/icons/inspector/class.png": "b51c515d49600ad24ad45076275c31e8",
"assets/icons/inspector/balloonInformation.png": "66959b2a139e824df331bee8dfa4f0d8",
"assets/icons/inspector/any_type@2x.png": "95983aecd59c10ca5fdc827fe1b79182",
"assets/icons/inspector/any_type.png": "e5fc0b367cff9a3aaac7c497042d5819",
"assets/icons/inspector/resume.png": "7580821b2fc68f2b4e3a04b9040e7886",
"assets/icons/inspector/formattedTextField@2x.png": "dd93276cf8763dcdcfe4145b61b9d077",
"assets/icons/inspector/scrollbar@2x.png": "a95734ab0f8e6f93583f297c729dbc1b",
"assets/icons/inspector/expand_property@2x.png": "a363d20c39ebb501b89e09ed0c3935e8",
"assets/icons/inspector/diagram@2x.png": "ad3ea98cb1bd5027fc0156b250fc00f6",
"assets/icons/inspector/value@2x.png": "7bc864d1ec9dd967e79ddd7355e2b177",
"assets/icons/inspector/extAnnotation.png": "2d3e029256b29d1e02634593e7283f4f",
"assets/icons/inspector/collapse_property.png": "63ec0cf8f0873997e73f881bf1eee51b",
"assets/icons/inspector/threads@2x.png": "19276711cd1286b34012108ed641d05e",
"assets/icons/inspector/textArea.png": "ec26da4275a1dbb50c42336bcc8040e3",
"assets/icons/inspector/colors.png": "51d32728d990baf55d1c8603118d6262",
"assets/icons/inspector/colors@2x.png": "2bcef4f4f40029c74db9eb6f40fcc7c1",
"assets/icons/inspector/renderer.png": "abba70711218f98be1cbd80463e00915",
"assets/icons/inspector/atrule@2x.png": "e518c17f245dcbc5806e1afd4e5c2971",
"assets/icons/inspector/atrule.png": "221cb98d10e94d2b44c775f36224e12d",
"assets/icons/inspector/balloonInformation@2x.png": "ad007ba7f02b955016c507c9d64cdc9f",
"assets/icons/inspector/expand_property.png": "b3d7c4bd44289f0968c38ec89cdd79be",
"assets/icons/inspector/renderer@2x.png": "072d5476b18f1cc51bff0ee9aff27914",
"assets/icons/inspector/collapse_property@2x.png": "471a3b684c8d048fc407a8a83ecdd0f2",
"assets/icons/inspector/resume@2x.png": "af62d4f95654101ecd37f1cba0faf088",
"assets/icons/inspector/widget_icons/hero.png": "f7ab159beabad8e7d8f715669240da35",
"assets/icons/inspector/widget_icons/outlinedbutton.png": "52e3b3d9f14d2c1bb33d75d0cb1199cb",
"assets/icons/inspector/widget_icons/pageView.png": "54c7c6f1cb4be2ba573e7b75a80f5823",
"assets/icons/inspector/widget_icons/alertdialog.png": "fb12c9b31ecb0bda718f5e39f461c0f3",
"assets/icons/inspector/widget_icons/gesture.png": "20865d03ff5b940993dea5f9f0cddb66",
"assets/icons/inspector/widget_icons/column.png": "ba90a4020806bf3c3811bfbfc17fca0c",
"assets/icons/inspector/widget_icons/onedot.png": "c640b0d60bd3db3d1355f4376ef1317e",
"assets/icons/inspector/widget_icons/inkwell.png": "c17c4d4d4141728e871c431165b3add7",
"assets/icons/inspector/widget_icons/card.png": "2aadf3d28581ebf37f094b46f0af525f",
"assets/icons/inspector/widget_icons/divider.png": "e5e56527f45dab5db1e80fb1f80a509b",
"assets/icons/inspector/widget_icons/text.png": "d02e5958da10a00d7c12bee031da1b15",
"assets/icons/inspector/widget_icons/sizedbox.png": "ad83cb57f2fb32b22773caff9553a371",
"assets/icons/inspector/widget_icons/circleavatar.png": "d3634dcb4595bff02ab3469c2d1d35c7",
"assets/icons/inspector/widget_icons/scaffold.png": "a399887cbfe8bb04f5dcb5d5262b78dd",
"assets/icons/inspector/widget_icons/wrap.png": "22245dfb35de6dcc0aa1c4af536242ef",
"assets/icons/inspector/widget_icons/expand.png": "0cbaa3279a7db3a5033359b801451638",
"assets/icons/inspector/widget_icons/root.png": "36ff14a8361cbd7ba0d65b63ef63bddc",
"assets/icons/inspector/widget_icons/floatingab.png": "bb666ba729a2d2e9a4698500df6d958f",
"assets/icons/inspector/widget_icons/icon.png": "968a01ce5ccd634f9d6417506f274af0",
"assets/icons/inspector/widget_icons/bottomnavigationbar.png": "43add4558bbc290cc3e3184b678e162d",
"assets/icons/inspector/widget_icons/tab.png": "b84113c8b21af80c72d3b0a685261e22",
"assets/icons/inspector/widget_icons/animated.png": "0268cba161bd9b09b6d245d5a5f8b09b",
"assets/icons/inspector/widget_icons/image.png": "5f829b850003a94bea919aa347468664",
"assets/icons/inspector/widget_icons/transition.png": "a4ee5e1aacb0331f69e5824319e57a27",
"assets/icons/inspector/widget_icons/appbar.png": "d3229fb9ddec1738c174b21856ecb328",
"assets/icons/inspector/widget_icons/gridview.png": "007fcfa17c2dbd549bf6ef2276e68257",
"assets/icons/inspector/widget_icons/align.png": "053ccd26ae9cde2021564859ec314350",
"assets/icons/inspector/widget_icons/row.png": "11a5580a3ad30a5e6cfd379dd4707c00",
"assets/icons/inspector/widget_icons/drawer.png": "5f81b17caa7bc3c9e6a6f61849546c7d",
"assets/icons/inspector/widget_icons/listview.png": "c17c36d026957196c758b2c9b085ada4",
"assets/icons/inspector/widget_icons/opacity.png": "ee1db6a8c7e853c48bf44ebc20999273",
"assets/icons/inspector/widget_icons/textbutton.png": "54615439daaf425f01cddc8996066ee1",
"assets/icons/inspector/widget_icons/container.png": "4965e0d4cd464c284c49d386bb8aa4ac",
"assets/icons/inspector/widget_icons/center.png": "5cb1efbcca3eebc36998e9e041d4f9fe",
"assets/icons/inspector/widget_icons/checkbox.png": "67d53adc5cd56e0775737fa52dbdf3bb",
"assets/icons/inspector/widget_icons/circularprogress.png": "8958a2e86cd846e27ed6c6583bb21afe",
"assets/icons/inspector/widget_icons/material.png": "fb1f2e9031f435f89dd46ec62f2166bf",
"assets/icons/inspector/widget_icons/scroll.png": "aae3500cc61edf022391b57a73161f64",
"assets/icons/inspector/widget_icons/materialapp.png": "9029e24e53f4dc2f3e58a16f6378564c",
"assets/icons/inspector/widget_icons/stack.png": "dcdf78a831ce5bbe4e23dcf8f25d7991",
"assets/icons/inspector/widget_icons/radio.png": "3131280219804dae85105ab6a351bfbe",
"assets/icons/inspector/widget_icons/padding.png": "9d7628d427908de1bc2c33189e8fab95",
"assets/icons/inspector/widget_icons/constrainedbox.png": "2d125bab1721c8a11e9571b52cd5ccf1",
"assets/icons/inspector/widget_icons/toggle.png": "e6d0eb4e57986be9a10e11ca9456e497",
"assets/icons/inspector/diagram.png": "ace353bcabbdfadf7f45368f5c096451",
"assets/icons/inspector/formattedTextField.png": "e801db1e0d9a7eab6916399620a84fe8",
"assets/icons/inspector/textArea@2x.png": "f73ed1021eb2ce3d258d0396f2ffd562",
"assets/icons/inspector/extAnnotation@2x.png": "341f7f0934f50f8c643f8d328dc3d606",
"assets/icons/inspector/class@2x.png": "5ceef3bbe50abd73121b1357e6b27260",
"assets/icons/inspector/value.png": "add6641dc0440d02088a040125cf1c20",
"assets/icons/inspector/scrollbar.png": "513d5066fcb77212849b599b0d30967a",
"assets/icons/inspector/threads.png": "a140b95dd7103f1a923591bbd93edfc4",
"assets/icons/repaints-white.png": "f62c6acf836c2c0206dbc9c0b18d2e71",
"assets/icons/guidelines-white.png": "12b9c4436cbee70c842fa420071fb86c",
"assets/icons/baselines-white.png": "03f4a6affa38eb1a22a34cf07bb0c003",
"assets/icons/guidelines-dgrey.png": "916807c4ea77dff9caea8510211956f4",
"assets/icons/feedback@2x.png": "3fe67ddc2a05c25d67a70f4062035555",
"assets/icons/trackwidget-dgrey.png": "eac9e44db275e6bfe555afc6f79ead5b",
"assets/icons/hot-reload.png": "865893b75879a84123cc535af4f8122c",
"assets/icons/widget-select-white.png": "a9bbc2a08587572eb2ed2536644082fb",
"assets/icons/hot-restart@2x.png": "0850aa256e3d864f4d6aa23cf68e699a",
"assets/icons/hot-restart-white@2x.png": "5407e1c2596f79a5fbe373bffe01939b",
"assets/icons/images-white.png": "18f596e4fe4900128322afc5f513c25a",
"assets/icons/refresh-white.png": "80ce04a78cab204504d2d262820656f5",
"assets/icons/observatory_overflow@2x.png": "cb6ded75e5a9993305da466c5e19c41e",
"assets/icons/flutter_test@2x.png": "2395ee067da4de674745d943a9d204c8",
"assets/icons/reload_both@2x.png": "9efaa38f3578de57e3f98b6dcd22bdc6",
"assets/icons/flutter_test.png": "ed5edbeba30a69da4d1081614b9522e3",
"assets/icons/general/tbShown.svg": "3780e46534a05a9f16c5d5887314b96a",
"assets/icons/general/pause_black_disabled.png": "7dbdece627bd96762137b5e12d3b23c8",
"assets/icons/general/information.png": "65c12280149d93f4d67499d492c4b783",
"assets/icons/general/locateHover_dark.png": "1062dff85c14cce54ca5e04d179353e4",
"assets/icons/general/locateHover@2x.png": "eb111d907e1c3e49883ceab21f8620ac",
"assets/icons/general/locate.png": "895b8ec8017234555f34b03bdb597caa",
"assets/icons/general/locate@2x.png": "f740c86f8c9a6c1764248cfdafe146eb",
"assets/icons/general/pause_black_disabled@2x.png": "f381ea1d29ca222692a5ebffba2b10e5",
"assets/icons/general/pause_white_disabled@2x.png": "8bd2e45cfb1a88e9893635c46c036e2e",
"assets/icons/general/locateHover@2x_dark.png": "5322b4d44ea4ee02aa445fb022539c2a",
"assets/icons/general/locateHover.png": "266be4b27119d9b6a195729b6c60df11",
"assets/icons/general/lightbulb_outline.png": "bbcdd7fc5d7b8a3fa3c97dd46b451aa5",
"assets/icons/general/resume_white_disabled@2x.png": "8a893125faabed96b2ebd2ef8f63ddfa",
"assets/icons/general/resume_black_disabled@2x.png": "a04748510be66d9fd21422d40643c231",
"assets/icons/general/pause_white_disabled.png": "42b4bf47a5f685db593a40506eaecd8d",
"assets/icons/general/resume_white@2x.png": "b7a04fbc72a61cd185608888c70329aa",
"assets/icons/general/pause_white@2x.png": "954808b748c00535beff9177f2ac21cb",
"assets/icons/general/resume_black@2x.png": "15b596a73d9362f2e84cfbac6581b0c9",
"assets/icons/general/resume_black_disabled.png": "4a546a3295607f2d83deca6a2a099764",
"assets/icons/general/lightbulb_outline@2x.png": "3a999b7b3d5432c691a5e200dc86232b",
"assets/icons/general/tbShown_dark.svg": "71f94e65889d8befa7f9600f1793ddfd",
"assets/icons/general/resume_white.png": "521c2e6a11fc72fba4a4d13dca59a53b",
"assets/icons/general/locate_dark.png": "9b366b605ba591cc0b497ead678d6650",
"assets/icons/general/resume_black.png": "343a442a2d48725d6d263e510a9485d4",
"assets/icons/general/pause_black.png": "0c80e28a9604e6b7fe53759b4e6886b5",
"assets/icons/general/locate@2x_dark.png": "d8512f13a8e8d439c7e9ca9dcdbff992",
"assets/icons/general/resume_white_disabled.png": "1af530bdb784ec4ee96f27ebf9e8136d",
"assets/icons/general/pause_white.png": "86031638d9669173bf9735145a5841d3",
"assets/icons/general/pause_black@2x.png": "c3788f4e7b793732e98766dad7a06d7c",
"assets/icons/flutter_inspect.png": "c7d021902cdd8baf8ff0581b05300bbc",
"assets/icons/observatory@2x.png": "4f5435d75c69e7b35fd30f642b28c0cd",
"assets/icons/trackwidget-lgrey.png": "429049749d82b46643da164972c0ce05",
"assets/icons/refresh-lgrey.png": "056f7346b8861f004285650a789c9929",
"assets/icons/flutter_badge.png": "75ed887d7b88287f7432e38117f0e8da",
"assets/icons/timeline@2x.png": "044a8a35dbaa6f3fb4ef5cd64756b1b3",
"assets/icons/flutter_64@2x.png": "31ba1c09cfd2c66879e6d7fe8468205c",
"assets/icons/custom/class_abstract.png": "072ff98438b6d83e3af78958a6c3c5ff",
"assets/icons/custom/class.png": "b27dff60112e1420a9930f325c559e26",
"assets/icons/custom/bg-green.png": "0f2f2a7e6e916d455f7b3ff4827271ec",
"assets/icons/custom/property.png": "1f9efc724a939974822b09c5bac85d0e",
"assets/icons/custom/info@2x.png": "a481c659091c88aaa30a2397018e02dc",
"assets/icons/custom/interface.png": "c6fb38ed3bde0d617bc417276c033951",
"assets/icons/custom/info.png": "ecb655d03b857b581a046e45842baa46",
"assets/icons/custom/interface@2x.png": "9e8421464905cc8237d9ed5269e4b21d",
"assets/icons/custom/fields.png": "a7dfff5ff17cbc115deb88a79684902b",
"assets/icons/custom/method.png": "27756fcc95c2ab905317bbd1b6648b3b",
"assets/icons/custom/bg-gray-red.png": "a4f84d6e6f6c07c21cadc2da7634c64f",
"assets/icons/custom/property@2x.png": "5804ab4f3a03d069e56dc95876698012",
"assets/icons/custom/method_abstract.png": "d4fed792e3249c6520c122a8d76a3440",
"assets/icons/custom/bg-new-red.png": "4f545e5676c18796783885f459d73f62",
"assets/icons/custom/method@2x.png": "032597397a9d05feda57ddb97a36b461",
"assets/icons/custom/fields@2x.png": "f544485148bd04876a929add391389e6",
"assets/icons/repaints-lgrey.png": "3482b7c67e210abebc6d6fab92a4d362",
"assets/icons/widget-select-lgrey.png": "9896a16c8d2c3808b14907f551331958",
"assets/icons/perf/RedProgr_3@2x.png": "6637dcf3b02c3597cae6249eb2ba59f4",
"assets/icons/perf/red_progress.gif": "183c0960cdeae01bf48dfc038fc82b46",
"assets/icons/perf/YellowProgr_2@2x.png": "6a38afa0e7667e15ac3864e976bc86b1",
"assets/icons/perf/RedProgr_3.png": "a47575aad5e69b7f104906027e6a87a9",
"assets/icons/perf/GreenOK@2x.png": "5bf559e3f9fa7ded272a64d43c63cb7a",
"assets/icons/perf/GreyProgr@2x.png": "55ab615af7918cf9679e336d232d6532",
"assets/icons/perf/YellowProgr_5@2x.png": "0438cd52c76214cdf237228af034554d",
"assets/icons/perf/RedProgr_4@2x.png": "f540c7facb3118337561740f37cf145b",
"assets/icons/perf/YellowProgr_6@2x.png": "23a63f74f6325a5386289ddded040678",
"assets/icons/perf/GreyProgr_4.png": "f441611492868ab01d7b8680a1db7d3e",
"assets/icons/perf/RedProgr_5@2x.png": "113589bc7e627485bf2f9d2d3a45e5f0",
"assets/icons/perf/RedExcl.png": "cca59862a366809289e1f922e0b9e016",
"assets/icons/perf/YellowStr@2x.png": "feeb20f721020bc3c60eefda0154da65",
"assets/icons/perf/RedProgr_1@2x.png": "3c8d054241de2bab0a9354612121cdbd",
"assets/icons/perf/RedProgr_5.png": "6c467695d7161fc0e49371aaea1e90ef",
"assets/icons/perf/RedExcl@2x.png": "872ca936762bf516f99b7ca2482b8ef2",
"assets/icons/perf/RedProgr_8.png": "122c859ad570c00de7535b761ec87c21",
"assets/icons/perf/GreyProgr_2@2x.png": "4793e5364e0d59bbed0205afd4658d6d",
"assets/icons/perf/RedProgr@2x.png": "5b7f5e5e8c54762974778f18e3b6a4f3",
"assets/icons/perf/GreyProgr.png": "e6add7e1d045042900d1d00552a33845",
"assets/icons/perf/GreenOK.png": "29e53c41c07adf8108ae440363a1f1ff",
"assets/icons/perf/GreyProgr_3@2x.png": "7ff0758836fca86d41eae6afbf538e79",
"assets/icons/perf/YellowProgr_8.png": "fa7cc1166731596e4876cfea714d92f3",
"assets/icons/perf/RedProgr_8@2x.png": "d0ea4872eca720e084daf441c844a0f1",
"assets/icons/perf/GreyProgr_1@2x.png": "55ab615af7918cf9679e336d232d6532",
"assets/icons/perf/RedProgr_1.png": "fa81c9d18b726e639dc165deb064ce70",
"assets/icons/perf/YellowStr_dark.png": "b3f1c5158f62fa01c2cd21134d8cb356",
"assets/icons/perf/YellowProgr_7@2x.png": "d0e4d618f5f336ca2260468578f9d640",
"assets/icons/perf/GreyProgr_7@2x.png": "c01ea52ee631d000208eefa07fd94af4",
"assets/icons/perf/GreyProgr_5@2x.png": "7468e52d82d7567b1dc30e4417724931",
"assets/icons/perf/YellowProgr_3@2x.png": "b7c27a3108a8b59ef5e60ceb8c797600",
"assets/icons/perf/yellow_progress.gif": "81b651493d7bec4409e94c9244da90e8",
"assets/icons/perf/YellowStr.png": "aac8d0b52e9558a1e743c17a604be03d",
"assets/icons/perf/GreyProgr_3.png": "799c8ea45fc2644042fdd2142448473a",
"assets/icons/perf/YellowProgr_5.png": "fb0985324122c64459250c706bbd0e45",
"assets/icons/perf/GreyProgr_1.png": "b4e3c3667da88e11cc223df9cd25ac9b",
"assets/icons/perf/GreyProgr_5.png": "9f244fdc860444f6f389be12b5fab0de",
"assets/icons/perf/RedProgr_2@2x.png": "2c9732aec4cf7f1fcb0fe9f94540377d",
"assets/icons/perf/YellowProgr_1.png": "931d7a17f44871bf2131e575e68caee5",
"assets/icons/perf/GreyProgr_8.png": "8c9f87d07f1320385f0ccfe9ef41bdbc",
"assets/icons/perf/YellowProgr_2.png": "275229f6ffce2cd40046b67bb8f12ec5",
"assets/icons/perf/YellowProgr@2x.png": "08974875e52895fd5ba2fcbc68d11bc0",
"assets/icons/perf/RedProgr_7@2x.png": "773e2642c463c59abd4361ef40cc9278",
"assets/icons/perf/YellowProgr_3.png": "8891817a81bc7deca524d2bccfaa603d",
"assets/icons/perf/RedProgr_7.png": "7de867c115e9aecf52b49ff87b552853",
"assets/icons/perf/GreyProgr_8@2x.png": "76ead0039c3b5d40ca242208f061eb43",
"assets/icons/perf/GreyProgr_4@2x.png": "71516e40666d1d49e9bb8e418fe8fcbf",
"assets/icons/perf/YellowProgr_1@2x.png": "e6410d82dc4ea321ab99989b85bf5b11",
"assets/icons/perf/GreyProgr_2.png": "04c0175aa8ce80a6ca8a20d9eb3308a8",
"assets/icons/perf/YellowProgr_4@2x.png": "5715936de3b824350221f4a1c3e4f095",
"assets/icons/perf/YellowProgr_6.png": "ec2c01a57f8509c2780989c5c9115509",
"assets/icons/perf/RedProgr_2.png": "0230a95ceb8b5bec4fd19d4645ba6387",
"assets/icons/perf/YellowProgr_4.png": "6bde8eef6a9edecaad4138c8c397f5a7",
"assets/icons/perf/GreyProgr_7.png": "8546e961345b3026d84b2afa50f61895",
"assets/icons/perf/YellowProgr_8@2x.png": "8b5179241867d9bab7dc8a53649597a5",
"assets/icons/perf/GreyProgr_6@2x.png": "925d9c779906838fd779af8571ab9ff1",
"assets/icons/perf/RedProgr_6@2x.png": "6c03fcc0a888e884a20f9b13615f934a",
"assets/icons/perf/GreyProgr_6.png": "c2a9cc94ae5546f83d0f92c979c5ce1b",
"assets/icons/perf/RedProgr_4.png": "9d6c573bbcb6f914334b46ebe927beb4",
"assets/icons/perf/RedProgr_6.png": "f9113c84d24e0870b5ca67ed422d8392",
"assets/icons/perf/grey_progress.gif": "e3f69f349356b291fcf4e36d0a4520c7",
"assets/icons/perf/RedProgr.png": "1cdb016b1836be5ba0c96825c56220b0",
"assets/icons/perf/YellowProgr.png": "eb995c5e6e71ecdb9eeff1bda3254433",
"assets/icons/perf/YellowProgr_7.png": "783a4d5b40c05df47dd0c474bb56ca2c",
"assets/icons/perf/YellowStr@2x_dark.png": "de510f09b0fff82ef614d7b8420aa1e2",
"assets/icons/guidelines-lgrey.png": "5f008a545ad989e6b983bd26464ec285",
"assets/icons/images-dgrey.png": "964c00f7b09940bbdab4328a1b6e0e70",
"assets/icons/images-lgrey.png": "e0e007b11cfc22a7b7d98e8405326d72",
"assets/icons/timeline.png": "dda9878e3cb617682b9c782cb6509daf",
"assets/icons/slow-dgrey.png": "885e59b69a43d4bca0ff4e5b278e7838",
"assets/icons/reload_debug@2x.png": "ce6dd61540892dd86d472f874c98b3e2",
"assets/icons/slow-lgrey.png": "60e1fc4ea26cca20238403b7a7036f54",
"assets/icons/flutter_64.png": "7e24794e1094e8066c054c9d11827c92",
"assets/icons/memory/ic_delete_outline_black.png": "6effb40113caac0436161aa3f76c56b4",
"assets/icons/memory/snapshot_color.png": "8df3b10be937a176c92525b45d43a75c",
"assets/icons/memory/settings@2x.png": "dbc084367cf000c11f6e99d0567fde9c",
"assets/icons/memory/communities_black.png": "639a1977b222cf1cdaa017463a75bb20",
"assets/icons/memory/communities_white.png": "15403866729a0a1d6d01ec78fa479537",
"assets/icons/memory/alloc_icon@2x.png": "c9953a1256a8a80a26591957857072f5",
"assets/icons/memory/alloc_icon.png": "ff8d2823bc6a4e0a5daba30232ed579b",
"assets/icons/memory/settings.png": "fce912c8fc95518cb2a01a2666699778",
"assets/icons/memory/ic_delete_outline_black@2x.png": "6effb40113caac0436161aa3f76c56b4",
"assets/icons/memory/ic_filter_list_alt_black@2x.png": "6296e29222f3d96189d7b2fa85185018",
"assets/icons/memory/ic_filter_alt_black_1x_web_24dp@2x.png": "2428e54d768c84a4762a3157bdd4ec79",
"assets/icons/memory/reset_icon_black.png": "f5c5d5c810854b2809d3674ccf47518c",
"assets/icons/memory/ic_search@2x.png": "b2b093a97825a446b1d839056894940a",
"assets/icons/memory/reset_icon_white.png": "4dff1a11d56155a5345fea8ea016ace5",
"assets/icons/memory/ic_filter_list_alt_black.png": "2428e54d768c84a4762a3157bdd4ec79",
"assets/icons/memory/ic_search.png": "3ae481e0963d84dc500e5bc2a16dad44",
"assets/icons/memory/snapshot_color@2x.png": "67f45bfd98d5e507ffc9765f1cc8786b",
"assets/icons/debug_banner@2x.png": "f0669ee6cfba83e137744025addd2e3b",
"assets/icons/attachDebugger.png": "05ddbfda18764ac8ffca47adc532adcd",
"assets/icons/reload_run.png": "da0fcd427f812db380a1125949635bc7",
"assets/icons/memory_dashboard@2x.png": "42f218904aab471bd8410b7c840cc3bd",
"assets/icons/restart@2x.png": "b30dd7498339df8975ef657e73fac8d3",
"assets/icons/hot-reload-white@2x.png": "4a05189ee22691ea8af86173b520455d",
"assets/icons/reload_both.png": "128be73080038135fb7dc407a46b66a0",
"assets/icons/performance-lgrey.png": "8af2c63753ebc09206d49544f2f6a1f4",
"assets/icons/baselines-lgrey.png": "d24d1598ec6c6b337b4637712813372a",
"assets/icons/restart.png": "bd34e2904e6c0c911f4bb6d5add9b527",
"assets/icons/hot-reload-white.png": "6dc8bdd405672a75d0f925cb72465932",
"assets/icons/reload_run@2x.png": "c94136df1be445e7eb295856a84e5232",
"assets/icons/repaints-dgrey.png": "bac8721580a4fe236723cc0991ab3eea",
"assets/icons/bazel_run.png": "f6c7f8d3c28f847b72f427dd309073d9",
"assets/icons/flutter_badge@2x.png": "704de34ee538acf8a33affd40413ce95",
"assets/icons/flutter_inspect@2x.png": "82e208f934ddf23a55aeead145b0a664",
"assets/icons/phone.png": "17bdad06461783db7a974058095c209e",
"assets/assets/dart_syntax.json": "0be78a5fe219a59e85bbf02cfe69577e",
"assets/assets/img/legend/gc_manual_glyph.png": "349c615c9e195f071c82829edbce7175",
"assets/assets/img/legend/reset_glyph_light.png": "c355db8a4947899ad5b84e14bdb614b4",
"assets/assets/img/legend/gc_vm_glyph.png": "36361af2c4b9443328f5b855be9cbb23",
"assets/assets/img/legend/events_glyph.png": "601a078a480354b21b64da80215d9368",
"assets/assets/img/legend/reset_glyph_dark.png": "6e3bceed31316c3e605696fd32e59e3b",
"assets/assets/img/legend/snapshot_manual_glyph.png": "4e7a045cf0946df1c8e35f5844698b84",
"assets/assets/img/legend/snapshot_auto_glyph.png": "b239e01c8f8060a922e2ef1bbb5897ec",
"assets/assets/img/legend/monitor_glyph.png": "cc6c02ed012ed60d7054c96fe02e619f",
"assets/assets/img/legend/event_glyph.png": "55235d91d877980626fb16de5c305b82",
"assets/assets/img/star.png": "2b1babb5a3c9284b1d8352a894cc815f",
"assets/assets/img/layout_explorer/main_axis_alignment/row_end.png": "858726242cd94a22ccd91b815e0cca24",
"assets/assets/img/layout_explorer/main_axis_alignment/spaceBetween.png": "778053f426e7b976f14646a88a109d75",
"assets/assets/img/layout_explorer/main_axis_alignment/column_spaceAround.png": "d84a3cdbb3e9d6f3c1a65a9d01148cab",
"assets/assets/img/layout_explorer/main_axis_alignment/row_start.png": "70efb9159ed00a9a071dcc74b671ac54",
"assets/assets/img/layout_explorer/main_axis_alignment/row_spaceAround.png": "9e9b8dac4b96218d6044ec36b4265101",
"assets/assets/img/layout_explorer/main_axis_alignment/end.png": "146ee7ef9b3117a96ec4b5a825bc4044",
"assets/assets/img/layout_explorer/main_axis_alignment/start.png": "66c10848d8c33095c36bfbafb3401c43",
"assets/assets/img/layout_explorer/main_axis_alignment/column_spaceBetween.png": "0a7cba893b350ee92e4831739f81a15e",
"assets/assets/img/layout_explorer/main_axis_alignment/row_spaceBetween.png": "2ce44d15cbc6f6eb4209ccbb73499515",
"assets/assets/img/layout_explorer/main_axis_alignment/spaceAround.png": "1dc4535fec813a437becdf858ce70de2",
"assets/assets/img/layout_explorer/main_axis_alignment/column_end.png": "aeb15f23b9194c367c5b51fad3d4b93e",
"assets/assets/img/layout_explorer/main_axis_alignment/row_spaceEvenly.png": "e3b904bb030de3f1dc2401aeba94d9a5",
"assets/assets/img/layout_explorer/main_axis_alignment/spaceEvenly.png": "4a5ff5ea170ebceaa51539283b05b8a7",
"assets/assets/img/layout_explorer/main_axis_alignment/center.png": "b7f9b38c788e3664ed132cbc137bda99",
"assets/assets/img/layout_explorer/main_axis_alignment/row_center.png": "ae4385c1201ad2a3f7a62df87561f38b",
"assets/assets/img/layout_explorer/main_axis_alignment/column_center.png": "8c26475f866fbbaddcd0987946a72f32",
"assets/assets/img/layout_explorer/main_axis_alignment/column_spaceEvenly.png": "c8b5836b57e1a31595d7e8280054dab9",
"assets/assets/img/layout_explorer/main_axis_alignment/column_start.png": "99b7b6ea79c0b05103f34cce14396f4f",
"assets/assets/img/layout_explorer/negative_space_light.png": "5ae227b5f6b819becbcd9eb3b95986ed",
"assets/assets/img/layout_explorer/cross_axis_alignment/row_end.png": "46570b8c05c437243bb030f0c944950e",
"assets/assets/img/layout_explorer/cross_axis_alignment/row_start.png": "82e40210f8cb12c593c26f71a9fa62f5",
"assets/assets/img/layout_explorer/cross_axis_alignment/column_stretch.png": "cf75e7319e97aa87391b7aa00bc1a19e",
"assets/assets/img/layout_explorer/cross_axis_alignment/row_stretch.png": "41605dd05507bce094aa251f945d3e07",
"assets/assets/img/layout_explorer/cross_axis_alignment/stretch.png": "b5fb850467ee7506b7ae183329fdeb22",
"assets/assets/img/layout_explorer/cross_axis_alignment/end.png": "a85b3bbb0da27e0aaa471adf2554708d",
"assets/assets/img/layout_explorer/cross_axis_alignment/start.png": "b38f2686df7018d2533cccf18b067dcf",
"assets/assets/img/layout_explorer/cross_axis_alignment/baseline.png": "bdd4f7c12b43b03b67d880f29d86a220",
"assets/assets/img/layout_explorer/cross_axis_alignment/column_end.png": "4cce130517c6958f8bf578e23e770fed",
"assets/assets/img/layout_explorer/cross_axis_alignment/center.png": "06ee46b4827d383e2c70ab0b64e48b08",
"assets/assets/img/layout_explorer/cross_axis_alignment/row_center.png": "adc7dbdac9e1df897997b3f6e2138173",
"assets/assets/img/layout_explorer/cross_axis_alignment/column_center.png": "6c55fa8800db0a0649bcb6c60d725c86",
"assets/assets/img/layout_explorer/cross_axis_alignment/nobaseline.png": "c591def4d62de313ed913f7d95d70774",
"assets/assets/img/layout_explorer/cross_axis_alignment/column_start.png": "ba2854a71f06c7ab529a8f477b62b6df",
"assets/assets/img/layout_explorer/negative_space_dark.png": "82e6869910765b88b8736f130fd972bd",
"assets/assets/img/doc/upload_dark.png": "261eb42cca699db95c7966ba633f8ac9",
"assets/assets/img/doc/upload_light.png": "860cb45d8635fdb40c3d630d44bffe7e",
"assets/FontManifest.json": "5e6076aba326f0f10dd47fed80081eb1",
"assets/fonts/Roboto_Mono/RobotoMono-Medium.ttf": "7cfbd4284ec01b7ace2f8edb5cddae84",
"assets/fonts/Roboto_Mono/RobotoMono-Regular.ttf": "b4618f1f7f4cee0ac09873fcc5a966f9",
"assets/fonts/Roboto_Mono/RobotoMono-Light.ttf": "9d1044ccdbba0efa9a2bfc719a446702",
"assets/fonts/Roboto_Mono/RobotoMono-Bold.ttf": "7c13b04382bb3c4a6a50211300a1b072",
"assets/fonts/Roboto_Mono/RobotoMono-Thin.ttf": "288302ea531af8be59f6ac2b5bbbfdd3",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/fonts/Octicons.ttf": "73b8cff012825060b308d2162f31dbb2",
"assets/fonts/Roboto/Roboto-Medium.ttf": "d08840599e05db7345652d3d417574a9",
"assets/fonts/Roboto/Roboto-Light.ttf": "fc84e998bc29b297ea20321e4c90b6ed",
"assets/fonts/Roboto/Roboto-Bold.ttf": "ee7b96fa85d8fdb8c126409326ac2d2b",
"assets/fonts/Roboto/Roboto-Black.ttf": "ec4c9962ba54eb91787aa93d361c10a8",
"assets/fonts/Roboto/Roboto-Regular.ttf": "3e1af3ef546b9e6ecef9f3ba197bf7d2",
"assets/fonts/Roboto/Roboto-Thin.ttf": "89e2666c24d37055bcb60e9d2d9f7e35",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "133cca00dded366a91d494262682a698",
"assets/AssetManifest.json": "3416a0af2b597d222976fdb5f1f6183c",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/manifest.json": "7260873c701831d315ac1e1d6eb102fd",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/perfetto.css": "daecf002db95e45c330fc81bc79e1b39",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/engine_bundle.js": "0dc452eeba6466634dca762e56e2b76a",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/RobotoMono-Regular.woff2": "e92cc0fb9e1a7debc138224fd02a462a",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/RobotoCondensed-Regular.woff2": "e31e130d9ebbc2096ac69f8b49deae56",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/MaterialSymbolsOutlined.woff2": "5c73d34e4bfbfb932949822670d490d8",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/RobotoCondensed-Light.woff2": "2cb0ef8d990b644d2eadf55bb4ae28fb",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/Roboto-400.woff2": "aa23b7b4bcf2b8f0e876106bb3de69c6",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/favicon.png": "8fe57c90e818542279c4ee130f68813e",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/brand.png": "9777aa05f25d90abf2da909fc52ba1d5",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/logo-3d.png": "71b1db1f3c01644b9c1184aa132903dd",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/logo-128.png": "6bdbc795b27b9f7ec4fae4fd05cf0ed8",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/Roboto-500.woff2": "f00e7e4432f7c70d8c97efbe2c50d43b",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/Roboto-300.woff2": "80fe119e5efa3911b9d61b265f723b3d",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/scheduling_latency.png": "a6520b1969cfa35235ac383a90ed4128",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/assets/Roboto-100.woff2": "efdab736053df2248df0789a58e5f523",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/frontend_bundle.js": "c01d524c9542071477e585685e9addff",
"assets/packages/perfetto_ui_compiled/dist/v34.0-16f63abe3/trace_processor.wasm": "bc7e4d471f3d09124b1e0bec8723e155",
"assets/packages/perfetto_ui_compiled/dist/service_worker.js": "05abe3b99ca8431a932e2aa9514477f9",
"assets/packages/perfetto_ui_compiled/dist/devtools/devtools_dark.css": "35e019773c521ab3984f91de7f91fcd1",
"assets/packages/perfetto_ui_compiled/dist/devtools/devtools_light.css": "ede9a82285a2b4e9ed8b8e28ee713d1e",
"assets/packages/perfetto_ui_compiled/dist/devtools/devtools_theme_handler.js": "f25f31b7d741b46fc9f96c43368c5011",
"assets/packages/perfetto_ui_compiled/dist/devtools/devtools_shared.css": "ae4668a9989dfee81550738ad4d8a5c2",
"assets/packages/perfetto_ui_compiled/dist/index.html": "dfc2b40b1e86d6c66aa4e08667eab13b",
"assets/packages/devtools_app_shared/fonts/Roboto_Mono/RobotoMono-Medium.ttf": "7cfbd4284ec01b7ace2f8edb5cddae84",
"assets/packages/devtools_app_shared/fonts/Roboto_Mono/RobotoMono-Regular.ttf": "b4618f1f7f4cee0ac09873fcc5a966f9",
"assets/packages/devtools_app_shared/fonts/Roboto_Mono/RobotoMono-Light.ttf": "9d1044ccdbba0efa9a2bfc719a446702",
"assets/packages/devtools_app_shared/fonts/Roboto_Mono/RobotoMono-Bold.ttf": "7c13b04382bb3c4a6a50211300a1b072",
"assets/packages/devtools_app_shared/fonts/Roboto_Mono/RobotoMono-Thin.ttf": "288302ea531af8be59f6ac2b5bbbfdd3",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Medium.ttf": "d08840599e05db7345652d3d417574a9",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Light.ttf": "fc84e998bc29b297ea20321e4c90b6ed",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Bold.ttf": "ee7b96fa85d8fdb8c126409326ac2d2b",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Black.ttf": "ec4c9962ba54eb91787aa93d361c10a8",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Regular.ttf": "3e1af3ef546b9e6ecef9f3ba197bf7d2",
"assets/packages/devtools_app_shared/fonts/Roboto/Roboto-Thin.ttf": "89e2666c24d37055bcb60e9d2d9f7e35",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"devtools_analytics.js": "931f8ad8d0b829942213936d2d7e1299",
"favicon.png": "35ac27af3a3d8917ff1c7d3bf7e57bdd",
"flutter_bootstrap.js": "61c2da7695d50bf5a6970da9706c32cd",
"main.dart.js": "77e906420c087781fda47ccade31a0e4",
"index.html": "31a4597cf0584295a80ffdb51847d97f",
"/": "31a4597cf0584295a80ffdb51847d97f",
"styles.css": "9185fe0b57cd3d777131c99eeac6417c",
"main.dart.mjs": "a7575b3f9938746e9dd8db25941ed47d",
"unsupported-browser.html": "3a61587220af6e77a110d04e81257bcf",
"version.json": "6c75b33533baa97e3c7f3465d30e5739",
"main.dart.wasm": "9ccc50287811b89b874e19a5b6a010e1"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
