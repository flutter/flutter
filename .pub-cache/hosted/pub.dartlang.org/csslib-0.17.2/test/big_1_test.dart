// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library big_1_test;

import 'package:csslib/src/messages.dart';
import 'package:test/test.dart';
import 'testing.dart';

void compilePolyfillAndValidate(String input, String generated) {
  var errors = <Message>[];
  var stylesheet = polyFillCompileCss(input, errors: errors, opts: options);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void big_test() {
  var input = r'''
/********************************************************************
 * Kennedy colors
 ********************************************************************/
@kennedy-red: #dd4b39;
@kennedy-blue: #4d90fe;
@kennedy-green: #3d9400;

/********************************************************************
 * link colors
 ********************************************************************/
@link-color-1: #1155cc;
@link-color-2: #666666;

/********************************************************************
 * text and header colors
 ********************************************************************/
@text-color-emphasized-1: #222222;
@text-color-emphasized-2: #333333;
@text-color-regular: #666666;
@text-color-deemphasized-1: #777777;
@text-color-deemphasized-2: #999999;

/********************************************************************
 * icon colors
 ********************************************************************/
@zippy-icon-color: #b2b2b2;
@zippy-icon-color-hover: #666666;

@mutate-icon-color: #b2b2b2;

@silhouette-color: #8bb7fe;

/********************************************************************
 * Panel and Card colors
 ********************************************************************/
@panel-header-color: #f7f7f7;
@panel-body-color: #ffffff;
@panel-border-color: #dcdcdc;

/********************************************************************
 * App area colors
 ********************************************************************/
 @apparea-background-color: #f2f2f2;

/********************************************************************
 * Table colors
 ********************************************************************/
@table-row-numbers: #666666;
@table-row-item-links: #1155cc;
@table-row-item: #666666;

/* Borders */
@table-border-color: #dcdcdc;
@table-header-border-color: #dcdcdc;
@table-row-data-border-color: #eaeaea;

/* General column - USED: We are not currently spec'ing different colors
 * for the currently sorted/unsorted on column.
 */
@table-header-label-color: #666666;
@table-header-background-color: #f8f8f8;
@table-column-background-color: #ffffff;


/* Sorted column - UNUSED: We are not currently spec'ing different colors
 * for the currently sorted/unsorted on column.
 */
@table-sorted-header-label-color: #666666;
@table-sorted-header-background-color: #e6e6e6;
@table-sorted-column-background-color: #f8f8f8;

/* Unsorted column - UNUSED: We are not currently spec'ing different colors
 * for the currently sorted/unsorted on column.
 */
@table-unsorted-header-label-color: #999999;
@table-unsorted-header-background-color: #f8f8f8;
@table-unsorted-column-background-color: #ffffff;

@acux-border-color-1: #e5e5e5;
@acux-border-color-2: #3b7bea;
@acux-link-color: #3b7bea;
@acux-shell-background-color: #f2f2f2;

/********************************************************************
 * Tooltip and popup colors
 ********************************************************************/
@tooltip-border-color: #333;
@tooltip-color: #fff;
@popup-border-color: #fff;

/* Border radii */
@button-radius: 2px;

@mixin button-gradient(@from, @to) {
  background-color: @from;
  background-image: -webkit-linear-gradient(top, @from, @to);
  background-image: linear-gradient(top, @from, @to);
}

@mixin button-transition(@property, @time) {
  -webkit-transition: @property @time;
  transition: @property @time;
}

@mixin text-not-selectable() {
  -webkit-user-select: none;
  user-select: none;
}

/*
 * Buttons and their states
 */
@mixin btn-base {
  display: inline-block;
  min-width: 62px;
  text-align: center;
  font-size: 11px;
  font-weight: bold;
  height: 28px;
  padding: 0 8px;
  line-height: 27px;
  border-radius: @button-radius;
  cursor: default;

  color: #444;
  border: 1px solid rgba(0,0,0,0.1);
  @include button-transition(all, 0.218s);
  @include button-gradient(#f5f5f5, #f1f1f1);

  &:hover {
    border: 1px solid #C6C6C6;
    color: #222;
    box-shadow: 0px 1px 1px rgba(0,0,0,0.1);
    @include button-transition(all, 0s);
    @include button-gradient(#f8f8f8, #f1f1f1);
  }

  &:active {
    border: 1px solid #C6C6C6;
    color: #666;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.1);
    @include button-gradient(#f6f6f6, #f1f1f1);
  }

  &:focus {
    outline: none;
    border: 1px solid #4D90FE;
    z-index: 4 !important;
  }

  &.selected, &.popup-open {
    border: 1px solid #CCC;
    color: #666;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.1);
    @include button-gradient(#EEEEEE, #E0E0E0);
  }

  &.disabled, &.disabled:hover, &.disabled:active,
  &[disabled], &[disabled]:hover, &[disabled]:active {
    background: none;
    color: #b8b8b8;
    border: 1px solid rgba(0,0,0,0.05);
    cursor: default;
    pointer-events: none;
  }

  &.flat {
    background: none;
    border-color: transparent;
    padding: 0;
    box-shadow: none;
  }

  &.invalid {
    outline: none;
    border: 1px solid @kennedy-red;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.3);
  }
}

.btn-container {
  padding: 10px;
}

.btn {
  @include btn-base;
}

.btn-small {
  /* TODO(prsd): Implement using a mix-in. */
  min-width: 30px;
}

.btn-left {
  @include btn-base;
  border-radius: @button-radius 0 0 @button-radius;
  margin-right: 0;
  padding: 0;
  min-width: 30px;
}

.btn-right {
  @include btn-base;
  border-radius: 0 @button-radius @button-radius 0;
  border-left: none;
  margin-left: 0;
  padding: 0;
  min-width: 30px;
}

.btn + .btn {
  margin-left: 5px;
}

/* Primary Button and it's states */
.btn-primary {
  color: #FFF !important;
  width: 94px;
  border-color: #3079ed;
  @include button-gradient(#4d90fe, #4787ed);

  &:hover, &:active {
    border-color: #2f5bb7;
    @include button-gradient(#4d90fe, #357ae8);
  }

  &:focus {
    border-color: #4D90FE;
    box-shadow:inset 0 0 0 1px rgba(255,255,255,0.5);
  }

  &:focus:hover {
    box-shadow:inset 0 0 0 1px #fff, 0px 1px 1px rgba(0,0,0,0.1);
  }

  &.disabled, &.disabled:hover, &.disabled:active,
  &[disabled], &[disabled]:hover, &[disabled]:active {
    border-color:#3079ed;
    background-color: #4d90fe;
    opacity: 0.7;
  }
}

/* Checkbox displayed as a toggled button
 * Invisible checkbox followed by a label with 'for' set to checkbox */
input[type="checkbox"].toggle-button {
  display: none;

  & + label {
    @extend .btn;
  }

  &:checked + label,
  & + label.popup-open {
    border: 1px solid #CCC;
    color: #666;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.1);
    @include button-gradient(#EEEEEE, #E0E0E0);
  }
}

.txt-input {
  display:inline-block;
  *display:inline;
  *zoom:1;
  padding:4px 12px;
  margin-bottom:0;
  font-size:14px;
  line-height:20px;
  vertical-align:middle;
  color:#333333;
  border-color:#e6e6e6 #e6e6e6 #bfbfbf;
  border-color:rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
  border:1px solid #cccccc;
  *border:0;
  border-bottom-color:#b3b3b3;
  -webkit-border-radius:4px;
  -moz-border-radius:4px;
  border-radius:4px;
  *margin-left:.3em;
  -webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,.2), 0 1px 2px
  rgba(0,0,0,.05);
  -moz-box-shadow:inset 0 1px 0 rgba(255,255,255,.2), 0 1px 2px rgba(0,0,0,.05);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.2), 0 1px 2px rgba(0,0,0,.05);
}

input[type="text"], input:not([type]), .txt-input {
  height: 29px;
  background-color: white;
  padding: 4px 0 4px 8px;
  color: 333;
  border: 1px solid #d9d9d9;
  border-top: 1px solid #c0c0c0;
  display: inline-block;
  vertical-align: top;
  box-sizing: border-box;
  border-radius: 1px;

  &:hover {
    border: 1px solid #b9b9b9;
    border-top: 1px solid #a0a0a0;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.1);
  }

  &:focus {
    outline: none;
    border: 1px solid @kennedy-blue;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.3);
  }

  &.disabled, &.disabled:hover, &.disabled:active, &:disabled {
    background: #fff;
    border: 1px solid #f3f3f3;
    border: 1px solid rgba(0,0,0,0.05);
    color: #b8b8b8;
    cursor: default;
    pointer-events: none;
  }

  &.invalid, &:focus:invalid, &:required:invalid {
    outline: none;
    border: 1px solid @kennedy-red;
    box-shadow: inset 0px 1px 2px rgba(0,0,0,0.3);
  }
}

/* Text area */
textarea {
  @extend .txt-input;
  height: 3em;
}

/* Hide the spin button in datepickers */
input[type="date"]::-webkit-inner-spin-button,
input[type="datetime"]::-webkit-inner-spin-button,
input[type="datetime-local"]::-webkit-inner-spin-button,
input[type="month"]::-webkit-inner-spin-button,
input[type="time"]::-webkit-inner-spin-button,
input[type="week"]::-webkit-inner-spin-button {
  display: none;
}


/*
 * Selects & Dropdowns
 */
.dropdown-menu,
.popup {
  width: auto;
  padding: 0;
  margin: 0 0 0 1px;
  background: white;
  text-align: left;
  z-index: 1000;
  outline: 1px solid rgba(0,0,0,0.2);
  white-space: nowrap;
  list-style: none;
  box-shadow: 0px 2px 4px rgba(0,0,0,0.2);
  @include button-transition(opacity, 0.218s);
}

.popup {
  padding: 0 0 6px;
}
.dropdown-menu,
.popup {
  pointer-events: all;
}

.popup ul {
  margin: 0;
  padding: 0;
}
.popup li {
  list-style-type: none;
  padding: 5px 10px;
  cursor: default;
}
.popup .header {
  padding: 5px 10px;
}

 /* existing styles defined here */
.popup .divider,
.dropdown-menu .divider {
  width:100%;
  height:1px;
  padding: 0;
  overflow:hidden;
  background-color:#c0c0c0;
  border-bottom:1px solid @popup-border-color;
}

.dropdown-menu {
  max-height: 600px;
  overflow-x: hidden;
  overflow-y: auto;
}
.popup {
  overflow: hidden;
}

.dropdown-menuitem,
.dropdown-menu > li {
  display: block;
  padding: 6px 44px 6px 16px;
  color: #666;
  font-size:13px;
  font-weight: normal;
  cursor: default;
  margin: 0;
  text-decoration: none;
  @include text-not-selectable();

  &.disabled {
    color: #CCC;
    background-color: #FFF;
  }

  &:hover, &.selected {
    color: #222;
    background-color: #F1F1F1;
  }
}

.dropdown-menuheader {
  padding: 6px 44px 6px 16px;
  color: #666;
  font-size:11px;
  font-weight: bold;
  cursor: default;
  margin: 0;
  text-decoration: none;
  background-color: #F1F1F1;
  @include text-not-selectable();
}

li.dropdown-menudivider {
  width:100%;
  height:1px;
  padding: 0;
  overflow:hidden;
  background-color:#D0D0D0;
  border-bottom:1px solid #ffffff;
}

.btn-container {
  padding: 10px;
}

/*
 * Modal dialogs
 */

.modal-frame {
  position: relative;
  background-color: white;
  outline: 1px solid rgba(0, 0, 0, 0.2);
  padding: 30px 42px;
  min-width: 480px;
  z-index: 9000;
  pointer-events: auto;
  box-shadow: 0 4px 16px 0 rgba(0,0,0,0.2);

  @include button-transition(all, 0.218s);

  &.medium {
    padding: 28px 32px;
    min-width: 280px;
  }

  &.small {
    padding: 16px 20px;
  }

}

.modal-backdrop {
  background-color: rgba(0,0,0,0.1);
  position: fixed;
  height: 100%;
  width: 100%;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  z-index: 99;
  margin: 0;

  display: none;
  opacity: 0;
  @include button-transition(all, 0.218s);

  &.visible {
    display: -webkit-flex;
    display: flex;
    -webkit-align-items: center;
    align-items: center;
    -webkit-justify-content: space-around;
    justify-content: space-around;
    opacity: 1;
  }
}

/*
 * Scrollbars
 */

::-webkit-scrollbar {
  width: 10px;
  height: 10px;
  background: white;
}

::-webkit-scrollbar-button {
  height: 0px;
  width: 0px;

  &:start:decrement,
  &:end:increment {
    display: block;
  }

  &:vertical:start:increment,
  &:vertical:end:decrement {
    display: none;
  }
}

::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, .2);
  background-clip: padding-box;
  border: solid transparent;
  border-width: 1px 1px 1px 2px;
  min-height: 28px;
  padding: 100px 0 0;
  box-shadow: inset 1px 1px 0 rgba(0, 0, 0, .1),
              inset 0 -1px 0 rgba(0, 0, 0, .07);

  &:hover {
    background-color: rgba(0,0,0,0.4);
    -webkit-box-shadow: inset 1px 1px 1px rgba(0,0,0,0.25);
  }

  &:active {
    -webkit-box-shadow: inset 1px 1px 3px rgba(0,0,0,0.35);
    background-color: rgba(0,0,0,0.5);
  }

  &:vertical {
    border-top: 0px solid transparent;
    border-bottom: 0px solid transparent;
    border-right: 0px solid transparent;
    border-left: 1px solid transparent;
  }

  &:horizontal {
    border-top: 1px solid transparent;
    border-bottom: 0px solid transparent;
    border-right: 0px solid transparent;
    border-left: 0px solid transparent;
  }
}

::-webkit-scrollbar-track {
  background-clip: padding-box;
  background-color: white;

  &:hover {
    background-color: rgba(0,0,0,0.05);
    -webkit-box-shadow: inset 1px 0px 0px  rgba(0,0,0,0.10);
  }

  &:active {
    background-color: rgba(0,0,0,0.05);
    -webkit-box-shadow: inset 1px 0px 0px  rgba(0,0,0,0.14),
                        inset -1px -1px 0px  rgba(0,0,0,0.07);
  }

  &:vertical {
    border-right: 0px solid transparent;
    border-left: 1px solid transparent;
  }

  &:horizontal {
    border-bottom: 0px solid transparent;
    border-top: 1px solid transparent;
  }
}

/* Tooltips */
.tooltip {
  background: @tooltip-border-color;
  border-radius: 2px;
  color: @tooltip-color;
  padding: 4px 8px;
  font-size: 10px;
}

.tooltip a,
.tooltip div,
.tooltip span {
  color: @tooltip-color;
}
''';

  var generated = r'''.btn-container {
  padding: 10px;
}
.btn, input[type="checkbox"].toggle-button + label {
  display: inline-block;
  min-width: 62px;
  text-align: center;
  font-size: 11px;
  font-weight: bold;
  height: 28px;
  padding: 0 8px;
  line-height: 27px;
  border-radius: 2px;
  cursor: default;
  color: #444;
  border: 1px solid rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0.218s;
  transition: all 0.218s;
  background-color: #f5f5f5;
  background-image: -webkit-linear-gradient(top, #f5f5f5, #f1f1f1);
  background-image: linear-gradient(top, #f5f5f5, #f1f1f1);
}
.btn:hover, input[type="checkbox"].toggle-button + label:hover {
  border: 1px solid #C6C6C6;
  color: #222;
  box-shadow: 0px 1px 1px rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0s;
  transition: all 0s;
  background-color: #f8f8f8;
  background-image: -webkit-linear-gradient(top, #f8f8f8, #f1f1f1);
  background-image: linear-gradient(top, #f8f8f8, #f1f1f1);
}
.btn:active, input[type="checkbox"].toggle-button + label:active {
  border: 1px solid #C6C6C6;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #f6f6f6;
  background-image: -webkit-linear-gradient(top, #f6f6f6, #f1f1f1);
  background-image: linear-gradient(top, #f6f6f6, #f1f1f1);
}
.btn:focus, input[type="checkbox"].toggle-button + label:focus {
  outline: none;
  border: 1px solid #4D90FE;
  z-index: 4 !important;
}
.btn.selected, .btn.popup-open, input[type="checkbox"].toggle-button + label.selected, input[type="checkbox"].toggle-button + label.popup-open {
  border: 1px solid #CCC;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #EEE;
  background-image: -webkit-linear-gradient(top, #EEE, #E0E0E0);
  background-image: linear-gradient(top, #EEE, #E0E0E0);
}
.btn.disabled, .btn.disabled:hover, .btn.disabled:active, .btn[disabled], .btn[disabled]:hover, .btn[disabled]:active, input[type="checkbox"].toggle-button + label.disabled, input[type="checkbox"].toggle-button + label.disabled:hover, input[type="checkbox"].toggle-button + label.disabled:active, input[type="checkbox"].toggle-button + label[disabled], input[type="checkbox"].toggle-button + label[disabled]:hover, input[type="checkbox"].toggle-button + label[disabled]:active {
  background: none;
  color: #b8b8b8;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: default;
  pointer-events: none;
}
.btn.flat, input[type="checkbox"].toggle-button + label.flat {
  background: none;
  border-color: transparent;
  padding: 0;
  box-shadow: none;
}
.btn.invalid, input[type="checkbox"].toggle-button + label.invalid {
  outline: none;
  border: 1px solid #dd4b39;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.3);
}
.btn-small {
  min-width: 30px;
}
.btn-left {
  display: inline-block;
  min-width: 62px;
  text-align: center;
  font-size: 11px;
  font-weight: bold;
  height: 28px;
  padding: 0 8px;
  line-height: 27px;
  border-radius: 2px;
  cursor: default;
  color: #444;
  border: 1px solid rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0.218s;
  transition: all 0.218s;
  background-color: #f5f5f5;
  background-image: -webkit-linear-gradient(top, #f5f5f5, #f1f1f1);
  background-image: linear-gradient(top, #f5f5f5, #f1f1f1);
  border-radius: 2px 0 0 2px;
  margin-right: 0;
  padding: 0;
  min-width: 30px;
}
.btn-left:hover {
  border: 1px solid #C6C6C6;
  color: #222;
  box-shadow: 0px 1px 1px rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0s;
  transition: all 0s;
  background-color: #f8f8f8;
  background-image: -webkit-linear-gradient(top, #f8f8f8, #f1f1f1);
  background-image: linear-gradient(top, #f8f8f8, #f1f1f1);
}
.btn-left:active {
  border: 1px solid #C6C6C6;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #f6f6f6;
  background-image: -webkit-linear-gradient(top, #f6f6f6, #f1f1f1);
  background-image: linear-gradient(top, #f6f6f6, #f1f1f1);
}
.btn-left:focus {
  outline: none;
  border: 1px solid #4D90FE;
  z-index: 4 !important;
}
.btn-left.selected, .btn-left.popup-open {
  border: 1px solid #CCC;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #EEE;
  background-image: -webkit-linear-gradient(top, #EEE, #E0E0E0);
  background-image: linear-gradient(top, #EEE, #E0E0E0);
}
.btn-left.disabled, .btn-left.disabled:hover, .btn-left.disabled:active, .btn-left[disabled], .btn-left[disabled]:hover, .btn-left[disabled]:active {
  background: none;
  color: #b8b8b8;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: default;
  pointer-events: none;
}
.btn-left.flat {
  background: none;
  border-color: transparent;
  padding: 0;
  box-shadow: none;
}
.btn-left.invalid {
  outline: none;
  border: 1px solid #dd4b39;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.3);
}
.btn-right {
  display: inline-block;
  min-width: 62px;
  text-align: center;
  font-size: 11px;
  font-weight: bold;
  height: 28px;
  padding: 0 8px;
  line-height: 27px;
  border-radius: 2px;
  cursor: default;
  color: #444;
  border: 1px solid rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0.218s;
  transition: all 0.218s;
  background-color: #f5f5f5;
  background-image: -webkit-linear-gradient(top, #f5f5f5, #f1f1f1);
  background-image: linear-gradient(top, #f5f5f5, #f1f1f1);
  border-radius: 0 2px 2px 0;
  border-left: none;
  margin-left: 0;
  padding: 0;
  min-width: 30px;
}
.btn-right:hover {
  border: 1px solid #C6C6C6;
  color: #222;
  box-shadow: 0px 1px 1px rgba(0, 0, 0, 0.1);
  -webkit-transition: all 0s;
  transition: all 0s;
  background-color: #f8f8f8;
  background-image: -webkit-linear-gradient(top, #f8f8f8, #f1f1f1);
  background-image: linear-gradient(top, #f8f8f8, #f1f1f1);
}
.btn-right:active {
  border: 1px solid #C6C6C6;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #f6f6f6;
  background-image: -webkit-linear-gradient(top, #f6f6f6, #f1f1f1);
  background-image: linear-gradient(top, #f6f6f6, #f1f1f1);
}
.btn-right:focus {
  outline: none;
  border: 1px solid #4D90FE;
  z-index: 4 !important;
}
.btn-right.selected, .btn-right.popup-open {
  border: 1px solid #CCC;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #EEE;
  background-image: -webkit-linear-gradient(top, #EEE, #E0E0E0);
  background-image: linear-gradient(top, #EEE, #E0E0E0);
}
.btn-right.disabled, .btn-right.disabled:hover, .btn-right.disabled:active, .btn-right[disabled], .btn-right[disabled]:hover, .btn-right[disabled]:active {
  background: none;
  color: #b8b8b8;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: default;
  pointer-events: none;
}
.btn-right.flat {
  background: none;
  border-color: transparent;
  padding: 0;
  box-shadow: none;
}
.btn-right.invalid {
  outline: none;
  border: 1px solid #dd4b39;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.3);
}
.btn + .btn, input[type="checkbox"].toggle-button + label + .btn, .btn + input[type="checkbox"].toggle-button + label, input[type="checkbox"].toggle-button + label + input[type="checkbox"].toggle-button + label, input[type="checkbox"].toggle-button + label + input[type="checkbox"].toggle-button + label {
  margin-left: 5px;
}
.btn-primary {
  color: #FFF !important;
  width: 94px;
  border-color: #3079ed;
  background-color: #4d90fe;
  background-image: -webkit-linear-gradient(top, #4d90fe, #4787ed);
  background-image: linear-gradient(top, #4d90fe, #4787ed);
}
.btn-primary:hover, .btn-primary:active {
  border-color: #2f5bb7;
  background-color: #4d90fe;
  background-image: -webkit-linear-gradient(top, #4d90fe, #357ae8);
  background-image: linear-gradient(top, #4d90fe, #357ae8);
}
.btn-primary:focus {
  border-color: #4D90FE;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.5);
}
.btn-primary:focus:hover {
  box-shadow: inset 0 0 0 1px #fff, 0px 1px 1px rgba(0, 0, 0, 0.1);
}
.btn-primary.disabled, .btn-primary.disabled:hover, .btn-primary.disabled:active, .btn-primary[disabled], .btn-primary[disabled]:hover, .btn-primary[disabled]:active {
  border-color: #3079ed;
  background-color: #4d90fe;
  opacity: 0.7;
}
input[type="checkbox"].toggle-button {
  display: none;
}
input[type="checkbox"].toggle-button + label {
}
input[type="checkbox"].toggle-button:checked + label, input[type="checkbox"].toggle-button + label.popup-open {
  border: 1px solid #CCC;
  color: #666;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
  background-color: #EEE;
  background-image: -webkit-linear-gradient(top, #EEE, #E0E0E0);
  background-image: linear-gradient(top, #EEE, #E0E0E0);
}
.txt-input, textarea {
  display: inline-block;
  *display: inline;
  *zoom: 1;
  padding: 4px 12px;
  margin-bottom: 0;
  font-size: 14px;
  line-height: 20px;
  vertical-align: middle;
  color: #333;
  border-color: #e6e6e6 #e6e6e6 #bfbfbf;
  border-color: rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
  border: 1px solid #ccc;
  *border: 0;
  border-bottom-color: #b3b3b3;
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  *margin-left: .3em;
  -webkit-box-shadow: inset 0 1px 0 rgba(255, 255, 255, .2), 0 1px 2px rgba(0, 0, 0, .05);
  -moz-box-shadow: inset 0 1px 0 rgba(255, 255, 255, .2), 0 1px 2px rgba(0, 0, 0, .05);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .2), 0 1px 2px rgba(0, 0, 0, .05);
}
input[type="text"], input:not([type]), .txt-input, textarea {
  height: 29px;
  background-color: #fff;
  padding: 4px 0 4px 8px;
  color: 333;
  border: 1px solid #d9d9d9;
  border-top: 1px solid #c0c0c0;
  display: inline-block;
  vertical-align: top;
  box-sizing: border-box;
  border-radius: 1px;
}
input[type="text"]:hover, input:not([type]):hover, .txt-input:hover, textarea:hover {
  border: 1px solid #b9b9b9;
  border-top: 1px solid #a0a0a0;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.1);
}
input[type="text"]:focus, input:not([type]):focus, .txt-input:focus, textarea:focus {
  outline: none;
  border: 1px solid #4d90fe;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.3);
}
input[type="text"].disabled, input:not([type]).disabled, .txt-input.disabled, input[type="text"].disabled:hover, input:not([type]).disabled:hover, .txt-input.disabled:hover, input[type="text"].disabled:active, input:not([type]).disabled:active, .txt-input.disabled:active, input[type="text"]:disabled, input:not([type]):disabled, .txt-input:disabled, textarea.disabled, textarea.disabled:hover, textarea.disabled:active, textarea:disabled {
  background: #fff;
  border: 1px solid #f3f3f3;
  border: 1px solid rgba(0, 0, 0, 0.05);
  color: #b8b8b8;
  cursor: default;
  pointer-events: none;
}
input[type="text"].invalid, input:not([type]).invalid, .txt-input.invalid, input[type="text"]:focus:invalid, input:not([type]):focus:invalid, .txt-input:focus:invalid, input[type="text"]:required:invalid, input:not([type]):required:invalid, .txt-input:required:invalid, textarea.invalid, textarea:focus:invalid, textarea:required:invalid {
  outline: none;
  border: 1px solid #dd4b39;
  box-shadow: inset 0px 1px 2px rgba(0, 0, 0, 0.3);
}
textarea {
  height: 3em;
}
input[type="date"]::-webkit-inner-spin-button, input[type="datetime"]::-webkit-inner-spin-button, input[type="datetime-local"]::-webkit-inner-spin-button, input[type="month"]::-webkit-inner-spin-button, input[type="time"]::-webkit-inner-spin-button, input[type="week"]::-webkit-inner-spin-button {
  display: none;
}
.dropdown-menu, .popup {
  width: auto;
  padding: 0;
  margin: 0 0 0 1px;
  background: #fff;
  text-align: left;
  z-index: 1000;
  outline: 1px solid rgba(0, 0, 0, 0.2);
  white-space: nowrap;
  list-style: none;
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.2);
  -webkit-transition: opacity 0.218s;
  transition: opacity 0.218s;
}
.popup {
  padding: 0 0 6px;
}
.dropdown-menu, .popup {
  pointer-events: all;
}
.popup ul {
  margin: 0;
  padding: 0;
}
.popup li {
  list-style-type: none;
  padding: 5px 10px;
  cursor: default;
}
.popup .header {
  padding: 5px 10px;
}
.popup .divider, .dropdown-menu .divider {
  width: 100%;
  height: 1px;
  padding: 0;
  overflow: hidden;
  background-color: #c0c0c0;
  border-bottom: 1px solid #fff;
}
.dropdown-menu {
  max-height: 600px;
  overflow-x: hidden;
  overflow-y: auto;
}
.popup {
  overflow: hidden;
}
.dropdown-menuitem, .dropdown-menu > li {
  display: block;
  padding: 6px 44px 6px 16px;
  color: #666;
  font-size: 13px;
  font-weight: normal;
  cursor: default;
  margin: 0;
  text-decoration: none;
  -webkit-user-select: none;
  user-select: none;
}
.dropdown-menuitem.disabled, .dropdown-menu > li.disabled {
  color: #CCC;
  background-color: #FFF;
}
.dropdown-menuitem:hover, .dropdown-menu > li:hover, .dropdown-menuitem.selected, .dropdown-menu > li.selected {
  color: #222;
  background-color: #F1F1F1;
}
.dropdown-menuheader {
  padding: 6px 44px 6px 16px;
  color: #666;
  font-size: 11px;
  font-weight: bold;
  cursor: default;
  margin: 0;
  text-decoration: none;
  background-color: #F1F1F1;
  -webkit-user-select: none;
  user-select: none;
}
li.dropdown-menudivider {
  width: 100%;
  height: 1px;
  padding: 0;
  overflow: hidden;
  background-color: #D0D0D0;
  border-bottom: 1px solid #fff;
}
.btn-container {
  padding: 10px;
}
.modal-frame {
  position: relative;
  background-color: #fff;
  outline: 1px solid rgba(0, 0, 0, 0.2);
  padding: 30px 42px;
  min-width: 480px;
  z-index: 9000;
  pointer-events: auto;
  box-shadow: 0 4px 16px 0 rgba(0, 0, 0, 0.2);
  -webkit-transition: all 0.218s;
  transition: all 0.218s;
}
.modal-frame.medium {
  padding: 28px 32px;
  min-width: 280px;
}
.modal-frame.small {
  padding: 16px 20px;
}
.modal-backdrop {
  background-color: rgba(0, 0, 0, 0.1);
  position: fixed;
  height: 100%;
  width: 100%;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  z-index: 99;
  margin: 0;
  display: none;
  opacity: 0;
  -webkit-transition: all 0.218s;
  transition: all 0.218s;
}
.modal-backdrop.visible {
  display: -webkit-flex;
  display: flex;
  -webkit-align-items: center;
  align-items: center;
  -webkit-justify-content: space-around;
  justify-content: space-around;
  opacity: 1;
}
::-webkit-scrollbar {
  width: 10px;
  height: 10px;
  background: #fff;
}
::-webkit-scrollbar-button {
  height: 0px;
  width: 0px;
}
::-webkit-scrollbar-button:start:decrement, ::-webkit-scrollbar-button:end:increment {
  display: block;
}
::-webkit-scrollbar-button:vertical:start:increment, ::-webkit-scrollbar-button:vertical:end:decrement {
  display: none;
}
::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, .2);
  background-clip: padding-box;
  border: solid transparent;
  border-width: 1px 1px 1px 2px;
  min-height: 28px;
  padding: 100px 0 0;
  box-shadow: inset 1px 1px 0 rgba(0, 0, 0, .1), inset 0 -1px 0 rgba(0, 0, 0, .07);
}
::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.4);
  -webkit-box-shadow: inset 1px 1px 1px rgba(0, 0, 0, 0.25);
}
::-webkit-scrollbar-thumb:active {
  -webkit-box-shadow: inset 1px 1px 3px rgba(0, 0, 0, 0.35);
  background-color: rgba(0, 0, 0, 0.5);
}
::-webkit-scrollbar-thumb:vertical {
  border-top: 0px solid transparent;
  border-bottom: 0px solid transparent;
  border-right: 0px solid transparent;
  border-left: 1px solid transparent;
}
::-webkit-scrollbar-thumb:horizontal {
  border-top: 1px solid transparent;
  border-bottom: 0px solid transparent;
  border-right: 0px solid transparent;
  border-left: 0px solid transparent;
}
::-webkit-scrollbar-track {
  background-clip: padding-box;
  background-color: #fff;
}
::-webkit-scrollbar-track:hover {
  background-color: rgba(0, 0, 0, 0.05);
  -webkit-box-shadow: inset 1px 0px 0px rgba(0, 0, 0, 0.10);
}
::-webkit-scrollbar-track:active {
  background-color: rgba(0, 0, 0, 0.05);
  -webkit-box-shadow: inset 1px 0px 0px rgba(0, 0, 0, 0.14), inset -1px -1px 0px rgba(0, 0, 0, 0.07);
}
::-webkit-scrollbar-track:vertical {
  border-right: 0px solid transparent;
  border-left: 1px solid transparent;
}
::-webkit-scrollbar-track:horizontal {
  border-bottom: 0px solid transparent;
  border-top: 1px solid transparent;
}
.tooltip {
  background: #333;
  border-radius: 2px;
  color: #fff;
  padding: 4px 8px;
  font-size: 10px;
}
.tooltip a, .tooltip div, .tooltip span {
  color: #fff;
}''';

  compilePolyfillAndValidate(input, generated);
}

void main() {
  test('big #1', big_test);
}
