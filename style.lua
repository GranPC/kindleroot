styles = {}

local app = QApplication.new( select( '#', ... ) + 1, { 'lua', ... } ) -- this is a whole load of bs
_application = app

QFontDatabase.addApplicationFont( "fonts/Lato-Light.ttf" )
QFontDatabase.addApplicationFont( "fonts/OpenSans-Light.ttf" )
QFontDatabase.addApplicationFont( "fonts/OpenSans-Regular.ttf" )
QFontDatabase.addApplicationFont( "fonts/Lato-Bold.ttf" )

styles.main = [[
#container
{
	background: transparent;
}

QLabel, QRadioButton, QCheckBox
{
	color: #dddddd;
	font-family: 'Open Sans';
	qproperty-alignment: 'AlignLeft';
}

#title
{
	font-family: Lato;
	qproperty-alignment: 'AlignCenter';
	font-size: 16px;
	padding-top: 5px;
}

#error
{
	font-family: Lato;
	padding-top: 15px;
}

#titleshadow
{
	qproperty-alignment: 'AlignCenter';
	font-family: Lato;
	font-size: 16px;
	padding-top: 3px;
	color: rgba(0, 0, 0, 50%);
}

#info
{
	font-size: 15px;
}

#infovalues
{
	font-size: 15px;
	qproperty-alignment: 'AlignRight';
	font-family: "Open Sans Light";
}

#main
{
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #434343, stop: 1 #2e2e2e );
	border-radius: 6px;
}

QProgressBar
{
	border: 1px solid black;
	border-radius: 4px;
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #777777, stop: 0.06 #444444 stop: 1 #1b1b1b );
}

QProgressBar::chunk
{
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #0070FF stop: 1 #1B5899 );
	border-radius: 4px;
}

QProgressBar::chunk:indeterminate
{
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #0070FF stop: 1 #1B5899 );
	border-radius: 4px;
}

QPushButton[class=action]
{
	padding: 5px;
	font-family: Lato;
	font-size: 14px;
	padding: 6px;
	color: #ccc;
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #777777, stop: 0.06 #444444 stop: 1 #1b1b1b );
	border: 1px solid black;
	border-radius: 4px;
}

QPushButton[class=action]:pressed, QRadioButton::indicator:pressed, QCheckBox::indicator:pressed
{
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #777777, stop: 0.06 #303030, stop: 1 #161616 );
}

QRadioButton::indicator, QCheckBox::indicator
{
	width: 14px;
	height: 14px;
	border-radius: 8px;
	background: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #777777, stop: 0.06 #444444 stop: 1 #1b1b1b );
	border: 1px solid black;
	margin-right: 3px;
}

QCheckBox::indicator
{
	border-radius: 2px;
}

QRadioButton::indicator:checked, QCheckBox::indicator:checked
{
	background-image: url(images/indicator_dot.png);
	background-repeat: no-repeat;
	background-position: center center;
}

QCheckBox::indicator:checked
{
	background-image: url(images/indicator_check.png);
}

#close
{
	border-image: url(images/not_osx/close.png);
}

#close:hover
{
	border-image: url(images/not_osx/close_hover.png);
}

#minimize
{
	border-image: url(images/not_osx/minimize.png);
}

#minimize:hover
{
	border-image: url(images/not_osx/minimize_hover.png);
}

#maximize
{
	border-image: url(images/osx/grey.png);
}
]]

styles.osxnofocus = [[
#close, #minimize, #close:pressed, #minimize:pressed
{
	border-image: url(images/osx/grey.png);
}
]]

styles.osxfocus = [[
#close
{
	border-image: url(images/osx/close_focus.png);
}

#minimize
{
	border-image: url(images/osx/minimize_focus.png);
}
]]

styles.osxhover = [[
#close
{
	border-image: url(images/osx/close_hover.png);
}

#minimize
{
	border-image: url(images/osx/minimize_hover.png);
}

#close:pressed
{
	border-image: url(images/osx/close_down.png);
}

#minimize:pressed
{
	border-image: url(images/osx/minimize_down.png);
}
]]

_application:setStyleSheet( styles.main )
