var sys = require('sys');
var mustache = require('mustache');

function render(source, values) {
	var output = mustache.to_html(source, values);	
	sys.puts(output);	
}

render(
	"{{ # # foo }} {{ oi }} {{ / # foo }}",
	{'# foo': [{oi: 'OI!'}]}); // OI!

render(
	"{{ #foo }} {{ oi }} {{ /foo }}",
	{'foo': [{oi: 'OI!'}]}); // OI!

render(
	"{{{ #foo }}} {{{ /foo }}}",
	{'#foo': 1, '/foo': 2}); // 1 2

render(
	"{{{ { }}}",
	{'{': 1}); // 1

render(
	"{{ > }}",
	{'>': 'oi'}); // ''

render(
	"{{\nfoo}}",
	{'foo': 'bar'}); // bar

render(
	"{{\tfoo}}",
	{'foo': 'bar'}); // bar

render(
	"{{\t# foo}}oi{{\n/foo}}",
	{foo: true}); // oi

render(
	"{{{\tfoo\t}}}",
	{foo: true}); // oi


//render(
//	"{{ { }}",
//	{'{': 1}); // ERROR unclosed tag

//render(
//	"{{ { foo } }}",  
//	{'foo': 1}); // ERROR unclosed tag
