(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.k4(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a){a.immutable$list=Array
a.fixed$length=Array
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.eE(b)
return new s(c,this)}:function(){if(s===null)s=A.eE(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.eE(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
eJ(a,b,c,d){return{i:a,p:b,e:c,x:d}},
eG(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.eH==null){A.jQ()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.a(A.fe("Return interceptor for "+A.i(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.dm
if(o==null)o=$.dm=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.jV(a)
if(p!=null)return p
if(typeof a=="function")return B.J
s=Object.getPrototypeOf(a)
if(s==null)return B.w
if(s===Object.prototype)return B.w
if(typeof q=="function"){o=$.dm
if(o==null)o=$.dm=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.j,enumerable:false,writable:true,configurable:true})
return B.j}return B.j},
hQ(a,b){if(a<0||a>4294967295)throw A.a(A.H(a,0,4294967295,"length",null))
return J.hS(new Array(a),b)},
hR(a,b){if(a<0)throw A.a(A.a_("Length must be a non-negative integer: "+a,null))
return A.h(new Array(a),b.i("o<0>"))},
eX(a,b){if(a<0)throw A.a(A.a_("Length must be a non-negative integer: "+a,null))
return A.h(new Array(a),b.i("o<0>"))},
hS(a,b){return J.eg(A.h(a,b.i("o<0>")))},
eg(a){a.fixed$length=Array
return a},
eY(a){a.fixed$length=Array
a.immutable$list=Array
return a},
hT(a,b){return J.hu(a,b)},
X(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aP.prototype
return J.bI.prototype}if(typeof a=="string")return J.ai.prototype
if(a==null)return J.aQ.prototype
if(typeof a=="boolean")return J.bH.prototype
if(Array.isArray(a))return J.o.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a1.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.l)return a
return J.eG(a)},
ao(a){if(typeof a=="string")return J.ai.prototype
if(a==null)return a
if(Array.isArray(a))return J.o.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a1.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.l)return a
return J.eG(a)},
e_(a){if(a==null)return a
if(Array.isArray(a))return J.o.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a1.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.l)return a
return J.eG(a)},
jJ(a){if(typeof a=="number")return J.aR.prototype
if(typeof a=="string")return J.ai.prototype
if(a==null)return a
if(!(a instanceof A.l))return J.ax.prototype
return a},
F(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.X(a).F(a,b)},
hr(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.h4(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.ao(a).k(a,b)},
hs(a,b,c){if(typeof b==="number")if((Array.isArray(a)||A.h4(a,a[v.dispatchPropertyName]))&&!a.immutable$list&&b>>>0===b&&b<a.length)return a[b]=c
return J.e_(a).q(a,b,c)},
ht(a,b){return J.e_(a).X(a,b)},
hu(a,b){return J.jJ(a).aL(a,b)},
hv(a,b){return J.ao(a).ag(a,b)},
ef(a,b){return J.e_(a).E(a,b)},
Z(a){return J.X(a).gn(a)},
L(a){return J.e_(a).gB(a)},
aI(a){return J.ao(a).gl(a)},
hw(a){return J.X(a).gt(a)},
hx(a,b){return J.X(a).b_(a,b)},
aq(a){return J.X(a).h(a)},
bG:function bG(){},
bH:function bH(){},
aQ:function aQ(){},
aT:function aT(){},
a2:function a2(){},
bX:function bX(){},
ax:function ax(){},
a1:function a1(){},
aS:function aS(){},
aU:function aU(){},
o:function o(a){this.$ti=a},
cF:function cF(a){this.$ti=a},
ar:function ar(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aR:function aR(){},
aP:function aP(){},
bI:function bI(){},
ai:function ai(){}},A={eh:function eh(){},
hA(a,b,c){if(b.i("c<0>").b(a))return new A.b9(a,b.i("@<0>").A(c).i("b9<1,2>"))
return new A.af(a,b.i("@<0>").A(c).i("af<1,2>"))},
e0(a){var s,r=a^48
if(r<=9)return r
s=a|32
if(97<=s&&s<=102)return s-87
return-1},
a6(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
en(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
cn(a,b,c){return a},
eI(a){var s,r
for(s=$.ap.length,r=0;r<s;++r)if(a===$.ap[r])return!0
return!1},
hW(a,b,c,d){if(t.U.b(a))return new A.aM(a,b,c.i("@<0>").A(d).i("aM<1,2>"))
return new A.aj(a,b,c.i("@<0>").A(d).i("aj<1,2>"))},
eV(){return new A.b5("No element")},
a8:function a8(){},
bA:function bA(a,b){this.a=a
this.$ti=b},
af:function af(a,b){this.a=a
this.$ti=b},
b9:function b9(a,b){this.a=a
this.$ti=b},
b8:function b8(){},
M:function M(a,b){this.a=a
this.$ti=b},
aV:function aV(a){this.a=a},
bB:function bB(a){this.a=a},
cR:function cR(){},
c:function c(){},
J:function J(){},
au:function au(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aj:function aj(a,b,c){this.a=a
this.b=b
this.$ti=c},
aM:function aM(a,b,c){this.a=a
this.b=b
this.$ti=c},
av:function av(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
ak:function ak(a,b,c){this.a=a
this.b=b
this.$ti=c},
aO:function aO(){},
c1:function c1(){},
ay:function ay(){},
a5:function a5(a){this.a=a},
bp:function bp(){},
hG(){throw A.a(A.T("Cannot modify unmodifiable Map"))},
h9(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
h4(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.p.b(a)},
i(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.aq(a)
return s},
bY(a){var s,r=$.f2
if(r==null)r=$.f2=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
f3(a,b){var s,r,q,p,o,n=null,m=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(m==null)return n
s=m[3]
if(b==null){if(s!=null)return parseInt(a,10)
if(m[2]!=null)return parseInt(a,16)
return n}if(b<2||b>36)throw A.a(A.H(b,2,36,"radix",n))
if(b===10&&s!=null)return parseInt(a,10)
if(b<10||s==null){r=b<=10?47+b:86+b
q=m[1]
for(p=q.length,o=0;o<p;++o)if((q.charCodeAt(o)|32)>r)return n}return parseInt(a,b)},
cQ(a){return A.i0(a)},
i0(a){var s,r,q,p
if(a instanceof A.l)return A.C(A.aG(a),null)
s=J.X(a)
if(s===B.I||s===B.K||t.o.b(a)){r=B.l(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.C(A.aG(a),null)},
f4(a){if(a==null||typeof a=="number"||A.ez(a))return J.aq(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.ag)return a.h(0)
if(a instanceof A.bf)return a.aH(!0)
return"Instance of '"+A.cQ(a)+"'"},
i3(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
Q(a){var s
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.c.V(s,10)|55296)>>>0,s&1023|56320)}}throw A.a(A.H(a,0,1114111,null,null))},
a3(a,b,c){var s,r,q={}
q.a=0
s=[]
r=[]
q.a=b.length
B.b.aI(s,b)
q.b=""
if(c!=null&&c.a!==0)c.C(0,new A.cP(q,r,s))
return J.hx(a,new A.cD(B.ac,0,s,r,0))},
i1(a,b,c){var s,r,q
if(Array.isArray(b))s=c==null||c.a===0
else s=!1
if(s){r=b.length
if(r===0){if(!!a.$0)return a.$0()}else if(r===1){if(!!a.$1)return a.$1(b[0])}else if(r===2){if(!!a.$2)return a.$2(b[0],b[1])}else if(r===3){if(!!a.$3)return a.$3(b[0],b[1],b[2])}else if(r===4){if(!!a.$4)return a.$4(b[0],b[1],b[2],b[3])}else if(r===5)if(!!a.$5)return a.$5(b[0],b[1],b[2],b[3],b[4])
q=a[""+"$"+r]
if(q!=null)return q.apply(a,b)}return A.i_(a,b,c)},
i_(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g=Array.isArray(b)?b:A.bL(b,!0,t.z),f=g.length,e=a.$R
if(f<e)return A.a3(a,g,c)
s=a.$D
r=s==null
q=!r?s():null
p=J.X(a)
o=p.$C
if(typeof o=="string")o=p[o]
if(r){if(c!=null&&c.a!==0)return A.a3(a,g,c)
if(f===e)return o.apply(a,g)
return A.a3(a,g,c)}if(Array.isArray(q)){if(c!=null&&c.a!==0)return A.a3(a,g,c)
n=e+q.length
if(f>n)return A.a3(a,g,null)
if(f<n){m=q.slice(f-e)
if(g===b)g=A.bL(g,!0,t.z)
B.b.aI(g,m)}return o.apply(a,g)}else{if(f>e)return A.a3(a,g,c)
if(g===b)g=A.bL(g,!0,t.z)
l=Object.keys(q)
if(c==null)for(r=l.length,k=0;k<l.length;l.length===r||(0,A.co)(l),++k){j=q[l[k]]
if(B.n===j)return A.a3(a,g,c)
B.b.ad(g,j)}else{for(r=l.length,i=0,k=0;k<l.length;l.length===r||(0,A.co)(l),++k){h=l[k]
if(c.H(h)){++i
B.b.ad(g,c.k(0,h))}else{j=q[h]
if(B.n===j)return A.a3(a,g,c)
B.b.ad(g,j)}}if(i!==c.a)return A.a3(a,g,c)}return o.apply(a,g)}},
i2(a){var s=a.$thrownJsError
if(s==null)return null
return A.ac(s)},
eF(a,b){var s,r="index"
if(!A.fP(b))return new A.G(!0,b,r,null)
s=J.aI(a)
if(b<0||b>=s)return A.eU(b,s,a,r)
return A.i4(b,r)},
jG(a,b,c){if(a>c)return A.H(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return A.H(b,a,c,"end",null)
return new A.G(!0,b,"end",null)},
jz(a){return new A.G(!0,a,null,null)},
a(a){return A.h3(new Error(),a)},
h3(a,b){var s
if(b==null)b=new A.R()
a.dartException=b
s=A.k5
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:s})
a.name=""}else a.toString=s
return a},
k5(){return J.aq(this.dartException)},
aH(a){throw A.a(a)},
h8(a,b){throw A.h3(b,a)},
co(a){throw A.a(A.as(a))},
S(a){var s,r,q,p,o,n
a=A.k_(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.h([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.cU(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
cV(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
fd(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
ei(a,b){var s=b==null,r=s?null:b.method
return new A.bJ(a,r,s?null:b.receiver)},
ae(a){if(a==null)return new A.cO(a)
if(a instanceof A.aN)return A.ad(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.ad(a,a.dartException)
return A.jy(a)},
ad(a,b){if(t.Q.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
jy(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.c.V(r,16)&8191)===10)switch(q){case 438:return A.ad(a,A.ei(A.i(s)+" (Error "+q+")",null))
case 445:case 5007:A.i(s)
return A.ad(a,new A.b1())}}if(a instanceof TypeError){p=$.ha()
o=$.hb()
n=$.hc()
m=$.hd()
l=$.hg()
k=$.hh()
j=$.hf()
$.he()
i=$.hj()
h=$.hi()
g=p.D(s)
if(g!=null)return A.ad(a,A.ei(s,g))
else{g=o.D(s)
if(g!=null){g.method="call"
return A.ad(a,A.ei(s,g))}else if(n.D(s)!=null||m.D(s)!=null||l.D(s)!=null||k.D(s)!=null||j.D(s)!=null||m.D(s)!=null||i.D(s)!=null||h.D(s)!=null)return A.ad(a,new A.b1())}return A.ad(a,new A.c0(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.b4()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.ad(a,new A.G(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.b4()
return a},
ac(a){var s
if(a instanceof A.aN)return a.b
if(a==null)return new A.bg(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.bg(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
h5(a){if(a==null)return J.Z(a)
if(typeof a=="object")return A.bY(a)
return J.Z(a)},
jI(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.q(0,a[s],a[r])}return b},
jb(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.a(new A.d9("Unsupported number of arguments for wrapped closure"))},
aF(a,b){var s=a.$identity
if(!!s)return s
s=A.jE(a,b)
a.$identity=s
return s},
jE(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.jb)},
hF(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.cS().constructor.prototype):Object.create(new A.aJ(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.eT(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.hB(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.eT(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
hB(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.a("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.hy)}throw A.a("Error in functionType of tearoff")},
hC(a,b,c,d){var s=A.eS
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
eT(a,b,c,d){if(c)return A.hE(a,b,d)
return A.hC(b.length,d,a,b)},
hD(a,b,c,d){var s=A.eS,r=A.hz
switch(b?-1:a){case 0:throw A.a(new A.bZ("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
hE(a,b,c){var s,r
if($.eQ==null)$.eQ=A.eP("interceptor")
if($.eR==null)$.eR=A.eP("receiver")
s=b.length
r=A.hD(s,c,a,b)
return r},
eE(a){return A.hF(a)},
hy(a,b){return A.bl(v.typeUniverse,A.aG(a.a),b)},
eS(a){return a.a},
hz(a){return a.b},
eP(a){var s,r,q,p=new A.aJ("receiver","interceptor"),o=J.eg(Object.getOwnPropertyNames(p))
for(s=o.length,r=0;r<s;++r){q=o[r]
if(p[q]===a)return q}throw A.a(A.a_("Field name "+a+" not found.",null))},
kH(a){throw A.a(new A.c8(a))},
jK(a){return v.getIsolateTag(a)},
jV(a){var s,r,q,p,o,n=$.h2.$1(a),m=$.dZ[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.e9[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.h_.$2(a,n)
if(q!=null){m=$.dZ[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.e9[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.ea(s)
$.dZ[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.e9[n]=s
return s}if(p==="-"){o=A.ea(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.h6(a,s)
if(p==="*")throw A.a(A.fe(n))
if(v.leafTags[n]===true){o=A.ea(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.h6(a,s)},
h6(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.eJ(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
ea(a){return J.eJ(a,!1,null,!!a.$iD)},
jX(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.ea(s)
else return J.eJ(s,c,null,null)},
jQ(){if(!0===$.eH)return
$.eH=!0
A.jR()},
jR(){var s,r,q,p,o,n,m,l
$.dZ=Object.create(null)
$.e9=Object.create(null)
A.jP()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.h7.$1(o)
if(n!=null){m=A.jX(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
jP(){var s,r,q,p,o,n,m=B.y()
m=A.aE(B.z,A.aE(B.A,A.aE(B.m,A.aE(B.m,A.aE(B.B,A.aE(B.C,A.aE(B.D(B.l),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.h2=new A.e1(p)
$.h_=new A.e2(o)
$.h7=new A.e3(n)},
aE(a,b){return a(b)||b},
jF(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
eZ(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=f?"g":"",n=function(g,h){try{return new RegExp(g,h)}catch(m){return m}}(a,s+r+q+p+o)
if(n instanceof RegExp)return n
throw A.a(A.z("Illegal RegExp pattern ("+String(n)+")",a,null))},
k2(a,b,c){var s=a.indexOf(b,c)
return s>=0},
k_(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
fX(a){return a},
k3(a,b,c,d){var s,r,q,p=new A.d3(b,a,0),o=t.F,n=0,m=""
for(;p.m();){s=p.d
if(s==null)s=o.a(s)
r=s.b
q=r.index
m=m+A.i(A.fX(B.a.j(a,n,q)))+A.i(c.$1(s))
n=q+r[0].length}p=m+A.i(A.fX(B.a.K(a,n)))
return p.charCodeAt(0)==0?p:p},
cg:function cg(a,b){this.a=a
this.b=b},
aL:function aL(a,b){this.a=a
this.$ti=b},
aK:function aK(){},
ah:function ah(a,b,c){this.a=a
this.b=b
this.$ti=c},
cD:function cD(a,b,c,d,e){var _=this
_.a=a
_.c=b
_.d=c
_.e=d
_.f=e},
cP:function cP(a,b,c){this.a=a
this.b=b
this.c=c},
cU:function cU(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
b1:function b1(){},
bJ:function bJ(a,b,c){this.a=a
this.b=b
this.c=c},
c0:function c0(a){this.a=a},
cO:function cO(a){this.a=a},
aN:function aN(a,b){this.a=a
this.b=b},
bg:function bg(a){this.a=a
this.b=null},
ag:function ag(){},
cs:function cs(){},
ct:function ct(){},
cT:function cT(){},
cS:function cS(){},
aJ:function aJ(a,b){this.a=a
this.b=b},
c8:function c8(a){this.a=a},
bZ:function bZ(a){this.a=a},
dp:function dp(){},
N:function N(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cG:function cG(a){this.a=a},
cJ:function cJ(a,b){this.a=a
this.b=b
this.c=null},
O:function O(a,b){this.a=a
this.$ti=b},
bK:function bK(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
e1:function e1(a){this.a=a},
e2:function e2(a){this.a=a},
e3:function e3(a){this.a=a},
bf:function bf(){},
cf:function cf(){},
cE:function cE(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
ce:function ce(a){this.b=a},
d3:function d3(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
j0(a){return a},
hX(a){return new Int8Array(a)},
hY(a){return new Uint8Array(a)},
V(a,b,c){if(a>>>0!==a||a>=c)throw A.a(A.eF(b,a))},
iX(a,b,c){var s
if(!(a>>>0!==a))s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw A.a(A.jG(a,b,c))
return b},
bM:function bM(){},
aZ:function aZ(){},
bN:function bN(){},
aw:function aw(){},
aX:function aX(){},
aY:function aY(){},
bO:function bO(){},
bP:function bP(){},
bQ:function bQ(){},
bR:function bR(){},
bS:function bS(){},
bT:function bT(){},
bU:function bU(){},
b_:function b_(){},
b0:function b0(){},
bb:function bb(){},
bc:function bc(){},
bd:function bd(){},
be:function be(){},
f7(a,b){var s=b.c
return s==null?b.c=A.er(a,b.x,!0):s},
em(a,b){var s=b.c
return s==null?b.c=A.bj(a,"a0",[b.x]):s},
f8(a){var s=a.w
if(s===6||s===7||s===8)return A.f8(a.x)
return s===12||s===13},
i5(a){return a.as},
bt(a){return A.ck(v.typeUniverse,a,!1)},
aa(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.aa(a1,s,a3,a4)
if(r===s)return a2
return A.fs(a1,r,!0)
case 7:s=a2.x
r=A.aa(a1,s,a3,a4)
if(r===s)return a2
return A.er(a1,r,!0)
case 8:s=a2.x
r=A.aa(a1,s,a3,a4)
if(r===s)return a2
return A.fq(a1,r,!0)
case 9:q=a2.y
p=A.aD(a1,q,a3,a4)
if(p===q)return a2
return A.bj(a1,a2.x,p)
case 10:o=a2.x
n=A.aa(a1,o,a3,a4)
m=a2.y
l=A.aD(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.ep(a1,n,l)
case 11:k=a2.x
j=a2.y
i=A.aD(a1,j,a3,a4)
if(i===j)return a2
return A.fr(a1,k,i)
case 12:h=a2.x
g=A.aa(a1,h,a3,a4)
f=a2.y
e=A.jv(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.fp(a1,g,e)
case 13:d=a2.y
a4+=d.length
c=A.aD(a1,d,a3,a4)
o=a2.x
n=A.aa(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.eq(a1,n,c,!0)
case 14:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.a(A.by("Attempted to substitute unexpected RTI kind "+a0))}},
aD(a,b,c,d){var s,r,q,p,o=b.length,n=A.dI(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.aa(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
jw(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.dI(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.aa(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
jv(a,b,c,d){var s,r=b.a,q=A.aD(a,r,c,d),p=b.b,o=A.aD(a,p,c,d),n=b.c,m=A.jw(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.cb()
s.a=q
s.b=o
s.c=m
return s},
h(a,b){a[v.arrayRti]=b
return a},
h1(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.jM(s)
return a.$S()}return null},
jS(a,b){var s
if(A.f8(b))if(a instanceof A.ag){s=A.h1(a)
if(s!=null)return s}return A.aG(a)},
aG(a){if(a instanceof A.l)return A.E(a)
if(Array.isArray(a))return A.am(a)
return A.ey(J.X(a))},
am(a){var s=a[v.arrayRti],r=t.b
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
E(a){var s=a.$ti
return s!=null?s:A.ey(a)},
ey(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.j9(a,s)},
j9(a,b){var s=a instanceof A.ag?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.iy(v.typeUniverse,s.name)
b.$ccache=r
return r},
jM(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.ck(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
jL(a){return A.an(A.E(a))},
eC(a){var s
if(a instanceof A.bf)return A.jH(a.$r,a.aB())
s=a instanceof A.ag?A.h1(a):null
if(s!=null)return s
if(t.k.b(a))return J.hw(a).a
if(Array.isArray(a))return A.am(a)
return A.aG(a)},
an(a){var s=a.r
return s==null?a.r=A.fL(a):s},
fL(a){var s,r,q=a.as,p=q.replace(/\*/g,"")
if(p===q)return a.r=new A.dA(a)
s=A.ck(v.typeUniverse,p,!0)
r=s.r
return r==null?s.r=A.fL(s):r},
jH(a,b){var s,r,q=b,p=q.length
if(p===0)return t.d
s=A.bl(v.typeUniverse,A.eC(q[0]),"@<0>")
for(r=1;r<p;++r)s=A.ft(v.typeUniverse,s,A.eC(q[r]))
return A.bl(v.typeUniverse,s,a)},
K(a){return A.an(A.ck(v.typeUniverse,a,!1))},
j8(a){var s,r,q,p,o,n,m=this
if(m===t.K)return A.W(m,a,A.jg)
if(!A.Y(m))s=m===t._
else s=!0
if(s)return A.W(m,a,A.jk)
s=m.w
if(s===7)return A.W(m,a,A.j4)
if(s===1)return A.W(m,a,A.fQ)
r=s===6?m.x:m
q=r.w
if(q===8)return A.W(m,a,A.jc)
if(r===t.S)p=A.fP
else if(r===t.i||r===t.H)p=A.jf
else if(r===t.N)p=A.ji
else p=r===t.y?A.ez:null
if(p!=null)return A.W(m,a,p)
if(q===9){o=r.x
if(r.y.every(A.jT)){m.f="$i"+o
if(o==="f")return A.W(m,a,A.je)
return A.W(m,a,A.jj)}}else if(q===11){n=A.jF(r.x,r.y)
return A.W(m,a,n==null?A.fQ:n)}return A.W(m,a,A.j2)},
W(a,b,c){a.b=c
return a.b(b)},
j7(a){var s,r=this,q=A.j1
if(!A.Y(r))s=r===t._
else s=!0
if(s)q=A.iU
else if(r===t.K)q=A.iS
else{s=A.bu(r)
if(s)q=A.j3}r.a=q
return r.a(a)},
cm(a){var s,r=a.w
if(!A.Y(a))if(!(a===t._))if(!(a===t.A))if(r!==7)if(!(r===6&&A.cm(a.x)))s=r===8&&A.cm(a.x)||a===t.P||a===t.T
else s=!0
else s=!0
else s=!0
else s=!0
else s=!0
return s},
j2(a){var s=this
if(a==null)return A.cm(s)
return A.jU(v.typeUniverse,A.jS(a,s),s)},
j4(a){if(a==null)return!0
return this.x.b(a)},
jj(a){var s,r=this
if(a==null)return A.cm(r)
s=r.f
if(a instanceof A.l)return!!a[s]
return!!J.X(a)[s]},
je(a){var s,r=this
if(a==null)return A.cm(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.l)return!!a[s]
return!!J.X(a)[s]},
j1(a){var s=this
if(a==null){if(A.bu(s))return a}else if(s.b(a))return a
A.fM(a,s)},
j3(a){var s=this
if(a==null)return a
else if(s.b(a))return a
A.fM(a,s)},
fM(a,b){throw A.a(A.ip(A.fi(a,A.C(b,null))))},
fi(a,b){return A.at(a)+": type '"+A.C(A.eC(a),null)+"' is not a subtype of type '"+b+"'"},
ip(a){return new A.bh("TypeError: "+a)},
B(a,b){return new A.bh("TypeError: "+A.fi(a,b))},
jc(a){var s=this,r=s.w===6?s.x:s
return r.x.b(a)||A.em(v.typeUniverse,r).b(a)},
jg(a){return a!=null},
iS(a){if(a!=null)return a
throw A.a(A.B(a,"Object"))},
jk(a){return!0},
iU(a){return a},
fQ(a){return!1},
ez(a){return!0===a||!1===a},
kt(a){if(!0===a)return!0
if(!1===a)return!1
throw A.a(A.B(a,"bool"))},
kv(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.a(A.B(a,"bool"))},
ku(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.a(A.B(a,"bool?"))},
kw(a){if(typeof a=="number")return a
throw A.a(A.B(a,"double"))},
ky(a){if(typeof a=="number")return a
if(a==null)return a
throw A.a(A.B(a,"double"))},
kx(a){if(typeof a=="number")return a
if(a==null)return a
throw A.a(A.B(a,"double?"))},
fP(a){return typeof a=="number"&&Math.floor(a)===a},
fE(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.a(A.B(a,"int"))},
kz(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.a(A.B(a,"int"))},
fF(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.a(A.B(a,"int?"))},
jf(a){return typeof a=="number"},
kA(a){if(typeof a=="number")return a
throw A.a(A.B(a,"num"))},
kC(a){if(typeof a=="number")return a
if(a==null)return a
throw A.a(A.B(a,"num"))},
kB(a){if(typeof a=="number")return a
if(a==null)return a
throw A.a(A.B(a,"num?"))},
ji(a){return typeof a=="string"},
fG(a){if(typeof a=="string")return a
throw A.a(A.B(a,"String"))},
kD(a){if(typeof a=="string")return a
if(a==null)return a
throw A.a(A.B(a,"String"))},
iT(a){if(typeof a=="string")return a
if(a==null)return a
throw A.a(A.B(a,"String?"))},
fU(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.C(a[q],b)
return s},
jp(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.fU(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.C(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
fN(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=", "
if(a5!=null){s=a5.length
if(a4==null){a4=A.h([],t.s)
r=null}else r=a4.length
q=a4.length
for(p=s;p>0;--p)a4.push("T"+(q+p))
for(o=t.X,n=t._,m="<",l="",p=0;p<s;++p,l=a2){m=B.a.b6(m+l,a4[a4.length-1-p])
k=a5[p]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===o))i=k===n
else i=!0
if(!i)m+=" extends "+A.C(k,a4)}m+=">"}else{m=""
r=null}o=a3.x
h=a3.y
g=h.a
f=g.length
e=h.b
d=e.length
c=h.c
b=c.length
a=A.C(o,a4)
for(a0="",a1="",p=0;p<f;++p,a1=a2)a0+=a1+A.C(g[p],a4)
if(d>0){a0+=a1+"["
for(a1="",p=0;p<d;++p,a1=a2)a0+=a1+A.C(e[p],a4)
a0+="]"}if(b>0){a0+=a1+"{"
for(a1="",p=0;p<b;p+=3,a1=a2){a0+=a1
if(c[p+1])a0+="required "
a0+=A.C(c[p+2],a4)+" "+c[p]}a0+="}"}if(r!=null){a4.toString
a4.length=r}return m+"("+a0+") => "+a},
C(a,b){var s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6)return A.C(a.x,b)
if(m===7){s=a.x
r=A.C(s,b)
q=s.w
return(q===12||q===13?"("+r+")":r)+"?"}if(m===8)return"FutureOr<"+A.C(a.x,b)+">"
if(m===9){p=A.jx(a.x)
o=a.y
return o.length>0?p+("<"+A.fU(o,b)+">"):p}if(m===11)return A.jp(a,b)
if(m===12)return A.fN(a,b,null)
if(m===13)return A.fN(a.x,b,a.y)
if(m===14){n=a.x
return b[b.length-1-n]}return"?"},
jx(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
iz(a,b){var s=a.tR[b]
for(;typeof s=="string";)s=a.tR[s]
return s},
iy(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.ck(a,b,!1)
else if(typeof m=="number"){s=m
r=A.bk(a,5,"#")
q=A.dI(s)
for(p=0;p<s;++p)q[p]=r
o=A.bj(a,b,q)
n[b]=o
return o}else return m},
ix(a,b){return A.fC(a.tR,b)},
iw(a,b){return A.fC(a.eT,b)},
ck(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.fn(A.fl(a,null,b,c))
r.set(b,s)
return s},
bl(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.fn(A.fl(a,b,c,!0))
q.set(c,r)
return r},
ft(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.ep(a,b,c.w===10?c.y:[c])
p.set(s,q)
return q},
U(a,b){b.a=A.j7
b.b=A.j8
return b},
bk(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.I(null,null)
s.w=b
s.as=c
r=A.U(a,s)
a.eC.set(c,r)
return r},
fs(a,b,c){var s,r=b.as+"*",q=a.eC.get(r)
if(q!=null)return q
s=A.iu(a,b,r,c)
a.eC.set(r,s)
return s},
iu(a,b,c,d){var s,r,q
if(d){s=b.w
if(!A.Y(b))r=b===t.P||b===t.T||s===7||s===6
else r=!0
if(r)return b}q=new A.I(null,null)
q.w=6
q.x=b
q.as=c
return A.U(a,q)},
er(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.it(a,b,r,c)
a.eC.set(r,s)
return s},
it(a,b,c,d){var s,r,q,p
if(d){s=b.w
if(!A.Y(b))if(!(b===t.P||b===t.T))if(s!==7)r=s===8&&A.bu(b.x)
else r=!0
else r=!0
else r=!0
if(r)return b
else if(s===1||b===t.A)return t.P
else if(s===6){q=b.x
if(q.w===8&&A.bu(q.x))return q
else return A.f7(a,b)}}p=new A.I(null,null)
p.w=7
p.x=b
p.as=c
return A.U(a,p)},
fq(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.ir(a,b,r,c)
a.eC.set(r,s)
return s},
ir(a,b,c,d){var s,r
if(d){s=b.w
if(A.Y(b)||b===t.K||b===t._)return b
else if(s===1)return A.bj(a,"a0",[b])
else if(b===t.P||b===t.T)return t.W}r=new A.I(null,null)
r.w=8
r.x=b
r.as=c
return A.U(a,r)},
iv(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.I(null,null)
s.w=14
s.x=b
s.as=q
r=A.U(a,s)
a.eC.set(q,r)
return r},
bi(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
iq(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
bj(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.bi(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.I(null,null)
r.w=9
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.U(a,r)
a.eC.set(p,q)
return q},
ep(a,b,c){var s,r,q,p,o,n
if(b.w===10){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.bi(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.I(null,null)
o.w=10
o.x=s
o.y=r
o.as=q
n=A.U(a,o)
a.eC.set(q,n)
return n},
fr(a,b,c){var s,r,q="+"+(b+"("+A.bi(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.I(null,null)
s.w=11
s.x=b
s.y=c
s.as=q
r=A.U(a,s)
a.eC.set(q,r)
return r},
fp(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.bi(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.bi(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.iq(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.I(null,null)
p.w=12
p.x=b
p.y=c
p.as=r
o=A.U(a,p)
a.eC.set(r,o)
return o},
eq(a,b,c,d){var s,r=b.as+("<"+A.bi(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.is(a,b,c,r,d)
a.eC.set(r,s)
return s},
is(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.dI(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.aa(a,b,r,0)
m=A.aD(a,c,r,0)
return A.eq(a,n,m,c!==m)}}l=new A.I(null,null)
l.w=13
l.x=b
l.y=c
l.as=d
return A.U(a,l)},
fl(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
fn(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.ii(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.fm(a,r,l,k,!1)
else if(q===46)r=A.fm(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.a9(a.u,a.e,k.pop()))
break
case 94:k.push(A.iv(a.u,k.pop()))
break
case 35:k.push(A.bk(a.u,5,"#"))
break
case 64:k.push(A.bk(a.u,2,"@"))
break
case 126:k.push(A.bk(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.ik(a,k)
break
case 38:A.ij(a,k)
break
case 42:p=a.u
k.push(A.fs(p,A.a9(p,a.e,k.pop()),a.n))
break
case 63:p=a.u
k.push(A.er(p,A.a9(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.fq(p,A.a9(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.ih(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.fo(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.im(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.a9(a.u,a.e,m)},
ii(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
fm(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===10)o=o.x
n=A.iz(s,o.x)[p]
if(n==null)A.aH('No "'+p+'" in "'+A.i5(o)+'"')
d.push(A.bl(s,o,n))}else d.push(p)
return m},
ik(a,b){var s,r=a.u,q=A.fk(a,b),p=b.pop()
if(typeof p=="string")b.push(A.bj(r,p,q))
else{s=A.a9(r,a.e,p)
switch(s.w){case 12:b.push(A.eq(r,s,q,a.n))
break
default:b.push(A.ep(r,s,q))
break}}},
ih(a,b){var s,r,q,p,o,n=null,m=a.u,l=b.pop()
if(typeof l=="number")switch(l){case-1:s=b.pop()
r=n
break
case-2:r=b.pop()
s=n
break
default:b.push(l)
r=n
s=r
break}else{b.push(l)
r=n
s=r}q=A.fk(a,b)
l=b.pop()
switch(l){case-3:l=b.pop()
if(s==null)s=m.sEA
if(r==null)r=m.sEA
p=A.a9(m,a.e,l)
o=new A.cb()
o.a=q
o.b=s
o.c=r
b.push(A.fp(m,p,o))
return
case-4:b.push(A.fr(m,b.pop(),q))
return
default:throw A.a(A.by("Unexpected state under `()`: "+A.i(l)))}},
ij(a,b){var s=b.pop()
if(0===s){b.push(A.bk(a.u,1,"0&"))
return}if(1===s){b.push(A.bk(a.u,4,"1&"))
return}throw A.a(A.by("Unexpected extended operation "+A.i(s)))},
fk(a,b){var s=b.splice(a.p)
A.fo(a.u,a.e,s)
a.p=b.pop()
return s},
a9(a,b,c){if(typeof c=="string")return A.bj(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.il(a,b,c)}else return c},
fo(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.a9(a,b,c[s])},
im(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.a9(a,b,c[s])},
il(a,b,c){var s,r,q=b.w
if(q===10){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==9)throw A.a(A.by("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.a(A.by("Bad index "+c+" for "+b.h(0)))},
jU(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.q(a,b,null,c,null,!1)?1:0
r.set(c,s)}if(0===s)return!1
if(1===s)return!0
return!0},
q(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(!A.Y(d))s=d===t._
else s=!0
if(s)return!0
r=b.w
if(r===4)return!0
if(A.Y(b))return!1
s=b.w
if(s===1)return!0
q=r===14
if(q)if(A.q(a,c[b.x],c,d,e,!1))return!0
p=d.w
s=b===t.P||b===t.T
if(s){if(p===8)return A.q(a,b,c,d.x,e,!1)
return d===t.P||d===t.T||p===7||p===6}if(d===t.K){if(r===8)return A.q(a,b.x,c,d,e,!1)
if(r===6)return A.q(a,b.x,c,d,e,!1)
return r!==7}if(r===6)return A.q(a,b.x,c,d,e,!1)
if(p===6){s=A.f7(a,d)
return A.q(a,b,c,s,e,!1)}if(r===8){if(!A.q(a,b.x,c,d,e,!1))return!1
return A.q(a,A.em(a,b),c,d,e,!1)}if(r===7){s=A.q(a,t.P,c,d,e,!1)
return s&&A.q(a,b.x,c,d,e,!1)}if(p===8){if(A.q(a,b,c,d.x,e,!1))return!0
return A.q(a,b,c,A.em(a,d),e,!1)}if(p===7){s=A.q(a,b,c,t.P,e,!1)
return s||A.q(a,b,c,d.x,e,!1)}if(q)return!1
s=r!==12
if((!s||r===13)&&d===t.Y)return!0
o=r===11
if(o&&d===t.L)return!0
if(p===13){if(b===t.g)return!0
if(r!==13)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.q(a,j,c,i,e,!1)||!A.q(a,i,e,j,c,!1))return!1}return A.fO(a,b.x,c,d.x,e,!1)}if(p===12){if(b===t.g)return!0
if(s)return!1
return A.fO(a,b,c,d,e,!1)}if(r===9){if(p!==9)return!1
return A.jd(a,b,c,d,e,!1)}if(o&&p===11)return A.jh(a,b,c,d,e,!1)
return!1},
fO(a3,a4,a5,a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.q(a3,a4.x,a5,a6.x,a7,!1))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.q(a3,p[h],a7,g,a5,!1))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.q(a3,p[o+h],a7,g,a5,!1))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.q(a3,k[h],a7,g,a5,!1))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;!0;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.q(a3,e[a+2],a7,g,a5,!1))return!1
break}}for(;b<d;){if(f[b+1])return!1
b+=3}return!0},
jd(a,b,c,d,e,f){var s,r,q,p,o,n=b.x,m=d.x
for(;n!==m;){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.bl(a,b,r[o])
return A.fD(a,p,null,c,d.y,e,!1)}return A.fD(a,b.y,null,c,d.y,e,!1)},
fD(a,b,c,d,e,f,g){var s,r=b.length
for(s=0;s<r;++s)if(!A.q(a,b[s],d,e[s],f,!1))return!1
return!0},
jh(a,b,c,d,e,f){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.q(a,r[s],c,q[s],e,!1))return!1
return!0},
bu(a){var s,r=a.w
if(!(a===t.P||a===t.T))if(!A.Y(a))if(r!==7)if(!(r===6&&A.bu(a.x)))s=r===8&&A.bu(a.x)
else s=!0
else s=!0
else s=!0
else s=!0
return s},
jT(a){var s
if(!A.Y(a))s=a===t._
else s=!0
return s},
Y(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
fC(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
dI(a){return a>0?new Array(a):v.typeUniverse.sEA},
I:function I(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
cb:function cb(){this.c=this.b=this.a=null},
dA:function dA(a){this.a=a},
ca:function ca(){},
bh:function bh(a){this.a=a},
ib(){var s,r,q={}
if(self.scheduleImmediate!=null)return A.jA()
if(self.MutationObserver!=null&&self.document!=null){s=self.document.createElement("div")
r=self.document.createElement("span")
q.a=null
new self.MutationObserver(A.aF(new A.d5(q),1)).observe(s,{childList:true})
return new A.d4(q,s,r)}else if(self.setImmediate!=null)return A.jB()
return A.jC()},
ic(a){self.scheduleImmediate(A.aF(new A.d6(a),0))},
id(a){self.setImmediate(A.aF(new A.d7(a),0))},
ie(a){A.io(0,a)},
io(a,b){var s=new A.dy()
s.bf(a,b)
return s},
fS(a){return new A.c5(new A.v($.r,a.i("v<0>")),a.i("c5<0>"))},
fK(a,b){a.$2(0,null)
b.b=!0
return b.a},
fH(a,b){A.iV(a,b)},
fJ(a,b){b.ae(a)},
fI(a,b){b.af(A.ae(a),A.ac(a))},
iV(a,b){var s,r,q=new A.dK(b),p=new A.dL(b)
if(a instanceof A.v)a.aG(q,p,t.z)
else{s=t.z
if(a instanceof A.v)a.au(q,p,s)
else{r=new A.v($.r,t.e)
r.a=8
r.c=a
r.aG(q,p,s)}}},
fZ(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.r.b1(new A.dY(s))},
cp(a,b){var s=A.cn(a,"error",t.K)
return new A.bz(s,b==null?A.eN(a):b)},
eN(a){var s
if(t.Q.b(a)){s=a.gR()
if(s!=null)return s}return B.H},
fj(a,b){var s,r
for(;s=a.a,(s&4)!==0;)a=a.c
if(a===b){b.S(new A.G(!0,a,null,"Cannot complete a future with itself"),A.f9())
return}s|=b.a&1
a.a=s
if((s&24)!==0){r=b.ab()
b.T(a)
A.ba(b,r)}else{r=b.c
b.aE(a)
a.aa(r)}},
ig(a,b){var s,r,q={},p=q.a=a
for(;s=p.a,(s&4)!==0;){p=p.c
q.a=p}if(p===b){b.S(new A.G(!0,p,null,"Cannot complete a future with itself"),A.f9())
return}if((s&24)===0){r=b.c
b.aE(p)
q.a.aa(r)
return}if((s&16)===0&&b.c==null){b.T(p)
return}b.a^=2
A.aC(null,null,b.b,new A.dd(q,b))},
ba(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;!0;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){f=f.c
A.eB(f.a,f.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.ba(g.a,f)
s.a=o
n=o.a}r=g.a
m=r.c
s.b=p
s.c=m
if(q){l=f.c
l=(l&1)!==0||(l&15)===8}else l=!0
if(l){k=f.b.b
if(p){r=r.b===k
r=!(r||r)}else r=!1
if(r){A.eB(m.a,m.b)
return}j=$.r
if(j!==k)$.r=k
else j=null
f=f.c
if((f&15)===8)new A.dk(s,g,p).$0()
else if(q){if((f&1)!==0)new A.dj(s,m).$0()}else if((f&2)!==0)new A.di(g,s).$0()
if(j!=null)$.r=j
f=s.c
if(f instanceof A.v){r=s.a.$ti
r=r.i("a0<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.U(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.fj(f,i)
return}}i=s.a.b
h=i.c
i.c=null
b=i.U(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
jq(a,b){if(t.C.b(a))return b.b1(a)
if(t.v.b(a))return a
throw A.a(A.eM(a,"onError",u.c))},
jn(){var s,r
for(s=$.aB;s!=null;s=$.aB){$.bs=null
r=s.b
$.aB=r
if(r==null)$.br=null
s.a.$0()}},
ju(){$.eA=!0
try{A.jn()}finally{$.bs=null
$.eA=!1
if($.aB!=null)$.eL().$1(A.h0())}},
fW(a){var s=new A.c6(a),r=$.br
if(r==null){$.aB=$.br=s
if(!$.eA)$.eL().$1(A.h0())}else $.br=r.b=s},
jt(a){var s,r,q,p=$.aB
if(p==null){A.fW(a)
$.bs=$.br
return}s=new A.c6(a)
r=$.bs
if(r==null){s.b=p
$.aB=$.bs=s}else{q=r.b
s.b=q
$.bs=r.b=s
if(q==null)$.br=s}},
k0(a){var s=null,r=$.r
if(B.d===r){A.aC(s,s,B.d,a)
return}A.aC(s,s,r,r.aJ(a))},
kb(a){A.cn(a,"stream",t.K)
return new A.ci()},
eB(a,b){A.jt(new A.dW(a,b))},
fT(a,b,c,d){var s,r=$.r
if(r===c)return d.$0()
$.r=c
s=r
try{r=d.$0()
return r}finally{$.r=s}},
js(a,b,c,d,e){var s,r=$.r
if(r===c)return d.$1(e)
$.r=c
s=r
try{r=d.$1(e)
return r}finally{$.r=s}},
jr(a,b,c,d,e,f){var s,r=$.r
if(r===c)return d.$2(e,f)
$.r=c
s=r
try{r=d.$2(e,f)
return r}finally{$.r=s}},
aC(a,b,c,d){if(B.d!==c)d=c.aJ(d)
A.fW(d)},
d5:function d5(a){this.a=a},
d4:function d4(a,b,c){this.a=a
this.b=b
this.c=c},
d6:function d6(a){this.a=a},
d7:function d7(a){this.a=a},
dy:function dy(){},
dz:function dz(a,b){this.a=a
this.b=b},
c5:function c5(a,b){this.a=a
this.b=!1
this.$ti=b},
dK:function dK(a){this.a=a},
dL:function dL(a){this.a=a},
dY:function dY(a){this.a=a},
bz:function bz(a,b){this.a=a
this.b=b},
c7:function c7(){},
b7:function b7(a,b){this.a=a
this.$ti=b},
az:function az(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
v:function v(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
da:function da(a,b){this.a=a
this.b=b},
dh:function dh(a,b){this.a=a
this.b=b},
de:function de(a){this.a=a},
df:function df(a){this.a=a},
dg:function dg(a,b,c){this.a=a
this.b=b
this.c=c},
dd:function dd(a,b){this.a=a
this.b=b},
dc:function dc(a,b){this.a=a
this.b=b},
db:function db(a,b,c){this.a=a
this.b=b
this.c=c},
dk:function dk(a,b,c){this.a=a
this.b=b
this.c=c},
dl:function dl(a){this.a=a},
dj:function dj(a,b){this.a=a
this.b=b},
di:function di(a,b){this.a=a
this.b=b},
c6:function c6(a){this.a=a
this.b=null},
ci:function ci(){},
dJ:function dJ(){},
dW:function dW(a,b){this.a=a
this.b=b},
dq:function dq(){},
dr:function dr(a,b){this.a=a
this.b=b},
f_(a,b,c){return A.jI(a,new A.N(b.i("@<0>").A(c).i("N<1,2>")))},
ej(a,b){return new A.N(a.i("@<0>").A(b).i("N<1,2>"))},
ek(a){var s,r={}
if(A.eI(a))return"{...}"
s=new A.y("")
try{$.ap.push(a)
s.a+="{"
r.a=!0
a.C(0,new A.cK(r,s))
s.a+="}"}finally{$.ap.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
e:function e(){},
P:function P(){},
cK:function cK(a,b){this.a=a
this.b=b},
cl:function cl(){},
aW:function aW(){},
a7:function a7(a,b){this.a=a
this.$ti=b},
bm:function bm(){},
jo(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.ae(r)
q=A.z(String(s),null,null)
throw A.a(q)}q=A.dM(p)
return q},
dM(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.cc(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.dM(a[s])
return a},
iQ(a,b,c){var s,r,q,p,o=c-b
if(o<=4096)s=$.hp()
else s=new Uint8Array(o)
for(r=J.ao(a),q=0;q<o;++q){p=r.k(a,b+q)
if((p&255)!==p)p=255
s[q]=p}return s},
iP(a,b,c,d){var s=a?$.ho():$.hn()
if(s==null)return null
if(0===c&&d===b.length)return A.fB(s,b)
return A.fB(s,b.subarray(c,d))},
fB(a,b){var s,r
try{s=a.decode(b)
return s}catch(r){}return null},
eO(a,b,c,d,e,f){if(B.c.a1(f,4)!==0)throw A.a(A.z("Invalid base64 padding, padded length must be multiple of four, is "+f,a,c))
if(d+e!==f)throw A.a(A.z("Invalid base64 padding, '=' not at the end",a,b))
if(e>2)throw A.a(A.z("Invalid base64 padding, more than two '=' characters",a,b))},
iR(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
cc:function cc(a,b){this.a=a
this.b=b
this.c=null},
cd:function cd(a){this.a=a},
dG:function dG(){},
dF:function dF(){},
cq:function cq(){},
cr:function cr(){},
bC:function bC(){},
bE:function bE(){},
cv:function cv(){},
cy:function cy(){},
cx:function cx(){},
cH:function cH(){},
cI:function cI(a){this.a=a},
d0:function d0(){},
d2:function d2(){},
dH:function dH(a){this.b=0
this.c=a},
d1:function d1(a){this.a=a},
dE:function dE(a){this.a=a
this.b=16
this.c=0},
e8(a,b){var s=A.f3(a,b)
if(s!=null)return s
throw A.a(A.z(a,null,null))},
hH(a,b){a=A.a(a)
a.stack=b.h(0)
throw a
throw A.a("unreachable")},
f0(a,b,c,d){var s,r=c?J.hR(a,d):J.hQ(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
hV(a,b,c){var s,r=A.h([],c.i("o<0>"))
for(s=J.L(a);s.m();)r.push(s.gp())
if(b)return r
return J.eg(r)},
bL(a,b,c){var s=A.hU(a,c)
return s},
hU(a,b){var s,r
if(Array.isArray(a))return A.h(a.slice(0),b.i("o<0>"))
s=A.h([],b.i("o<0>"))
for(r=J.L(a);r.m();)s.push(r.gp())
return s},
fc(a,b,c){var s,r
A.f5(b,"start")
if(c!=null){s=c-b
if(s<0)throw A.a(A.H(c,b,null,"end",null))
if(s===0)return""}r=A.i6(a,b,c)
return r},
i6(a,b,c){var s=a.length
if(b>=s)return""
return A.i3(a,b,c==null||c>s?s:c)},
f6(a,b){return new A.cE(a,A.eZ(a,!1,b,!1,!1,!1))},
fb(a,b,c){var s=J.L(b)
if(!s.m())return a
if(c.length===0){do a+=A.i(s.gp())
while(s.m())}else{a+=A.i(s.gp())
for(;s.m();)a=a+c+A.i(s.gp())}return a},
f1(a,b){return new A.bV(a,b.gbN(),b.gbQ(),b.gbO())},
fA(a,b,c,d){var s,r,q,p,o,n="0123456789ABCDEF"
if(c===B.e){s=$.hl()
s=s.b.test(b)}else s=!1
if(s)return b
r=B.G.I(b)
for(s=r.length,q=0,p="";q<s;++q){o=r[q]
if(o<128&&(a[o>>>4]&1<<(o&15))!==0)p+=A.Q(o)
else p=d&&o===32?p+"+":p+"%"+n[o>>>4&15]+n[o&15]}return p.charCodeAt(0)==0?p:p},
iH(a){var s,r,q
if(!$.hm())return A.iI(a)
s=new URLSearchParams()
a.C(0,new A.dD(s))
r=s.toString()
q=r.length
if(q>0&&r[q-1]==="=")r=B.a.j(r,0,q-1)
return r.replace(/=&|\*|%7E/g,b=>b==="=&"?"&":b==="*"?"%2A":"~")},
f9(){return A.ac(new Error())},
at(a){if(typeof a=="number"||A.ez(a)||a==null)return J.aq(a)
if(typeof a=="string")return JSON.stringify(a)
return A.f4(a)},
hI(a,b){A.cn(a,"error",t.K)
A.cn(b,"stackTrace",t.l)
A.hH(a,b)},
by(a){return new A.bx(a)},
a_(a,b){return new A.G(!1,null,b,a)},
eM(a,b,c){return new A.G(!0,a,b,c)},
i4(a,b){return new A.b2(null,null,!0,a,b,"Value not in range")},
H(a,b,c,d,e){return new A.b2(b,c,!0,a,d,"Invalid value")},
b3(a,b,c){if(0>a||a>c)throw A.a(A.H(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.a(A.H(b,a,c,"end",null))
return b}return c},
f5(a,b){if(a<0)throw A.a(A.H(a,0,null,b,null))
return a},
eU(a,b,c,d){return new A.bF(b,!0,a,d,"Index out of range")},
T(a){return new A.c2(a)},
fe(a){return new A.c_(a)},
fa(a){return new A.b5(a)},
as(a){return new A.bD(a)},
z(a,b,c){return new A.cw(a,b,c)},
hP(a,b,c){var s,r
if(A.eI(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.h([],t.s)
$.ap.push(a)
try{A.jl(a,s)}finally{$.ap.pop()}r=A.fb(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
eW(a,b,c){var s,r
if(A.eI(a))return b+"..."+c
s=new A.y(b)
$.ap.push(a)
try{r=s
r.a=A.fb(r.a,a,", ")}finally{$.ap.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
jl(a,b){var s,r,q,p,o,n,m,l=a.gB(a),k=0,j=0
while(!0){if(!(k<80||j<3))break
if(!l.m())return
s=A.i(l.gp())
b.push(s)
k+=s.length+2;++j}if(!l.m()){if(j<=5)return
r=b.pop()
q=b.pop()}else{p=l.gp();++j
if(!l.m()){if(j<=4){b.push(A.i(p))
return}r=A.i(p)
q=b.pop()
k+=r.length+2}else{o=l.gp();++j
for(;l.m();p=o,o=n){n=l.gp();++j
if(j>100){while(!0){if(!(k>75&&j>3))break
k-=b.pop().length+2;--j}b.push("...")
return}}q=A.i(p)
r=A.i(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
while(!0){if(!(k>80&&b.length>3))break
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)b.push(m)
b.push(q)
b.push(r)},
hZ(a,b,c,d){var s
if(B.i===c){s=B.c.gn(a)
b=J.Z(b)
return A.en(A.a6(A.a6($.ee(),s),b))}if(B.i===d){s=B.c.gn(a)
b=J.Z(b)
c=J.Z(c)
return A.en(A.a6(A.a6(A.a6($.ee(),s),b),c))}s=B.c.gn(a)
b=J.Z(b)
c=J.Z(c)
d=J.Z(d)
d=A.en(A.a6(A.a6(A.a6(A.a6($.ee(),s),b),c),d))
return d},
c4(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=null,a4=a5.length
if(a4>=5){s=((a5.charCodeAt(4)^58)*3|a5.charCodeAt(0)^100|a5.charCodeAt(1)^97|a5.charCodeAt(2)^116|a5.charCodeAt(3)^97)>>>0
if(s===0)return A.ff(a4<a4?B.a.j(a5,0,a4):a5,5,a3).gb3()
else if(s===32)return A.ff(B.a.j(a5,5,a4),0,a3).gb3()}r=A.f0(8,0,!1,t.S)
r[0]=0
r[1]=-1
r[2]=-1
r[7]=-1
r[3]=0
r[4]=0
r[5]=a4
r[6]=a4
if(A.fV(a5,0,a4,0,r)>=14)r[7]=a4
q=r[1]
if(q>=0)if(A.fV(a5,0,q,20,r)===20)r[7]=q
p=r[2]+1
o=r[3]
n=r[4]
m=r[5]
l=r[6]
if(l<m)m=l
if(n<p)n=m
else if(n<=q)n=q+1
if(o<p)o=n
k=r[7]<0
if(k)if(p>q+3){j=a3
k=!1}else{i=o>0
if(i&&o+1===n){j=a3
k=!1}else{if(!B.a.v(a5,"\\",n))if(p>0)h=B.a.v(a5,"\\",p-1)||B.a.v(a5,"\\",p-2)
else h=!1
else h=!0
if(h){j=a3
k=!1}else{if(!(m<a4&&m===n+2&&B.a.v(a5,"..",n)))h=m>n+2&&B.a.v(a5,"/..",m-3)
else h=!0
if(h)j=a3
else if(q===4)if(B.a.v(a5,"file",0)){if(p<=0){if(!B.a.v(a5,"/",n)){g="file:///"
s=3}else{g="file://"
s=2}a5=g+B.a.j(a5,n,a4)
m+=s
l+=s
a4=a5.length
p=7
o=7
n=7}else if(n===m){++l
f=m+1
a5=B.a.J(a5,n,m,"/");++a4
m=f}j="file"}else if(B.a.v(a5,"http",0)){if(i&&o+3===n&&B.a.v(a5,"80",o+1)){l-=3
e=n-3
m-=3
a5=B.a.J(a5,o,n,"")
a4-=3
n=e}j="http"}else j=a3
else if(q===5&&B.a.v(a5,"https",0)){if(i&&o+4===n&&B.a.v(a5,"443",o+1)){l-=4
e=n-4
m-=4
a5=B.a.J(a5,o,n,"")
a4-=3
n=e}j="https"}else j=a3
k=!h}}}else j=a3
if(k)return new A.ch(a4<a5.length?B.a.j(a5,0,a4):a5,q,p,o,n,m,l,j)
if(j==null)if(q>0)j=A.iJ(a5,0,q)
else{if(q===0)A.aA(a5,0,"Invalid empty scheme")
j=""}if(p>0){d=q+3
c=d<p?A.iK(a5,d,p-1):""
b=A.iE(a5,p,o,!1)
i=o+1
if(i<n){a=A.f3(B.a.j(a5,i,n),a3)
a0=A.iG(a==null?A.aH(A.z("Invalid port",a5,i)):a,j)}else a0=a3}else{a0=a3
b=a0
c=""}a1=A.iF(a5,n,m,a3,j,b!=null)
a2=m<l?A.eu(a5,m+1,l,a3):a3
return A.es(j,c,b,a0,a1,a2,l<a4?A.iD(a5,l+1,a4):a3)},
fh(a){var s=t.N
return B.b.bH(A.h(a.split("&"),t.s),A.ej(s,s),new A.d_(B.e))},
ia(a,b,c){var s,r,q,p,o,n,m="IPv4 address should contain exactly 4 parts",l="each part must be in the range 0..255",k=new A.cX(a),j=new Uint8Array(4)
for(s=b,r=s,q=0;s<c;++s){p=a.charCodeAt(s)
if(p!==46){if((p^48)>9)k.$2("invalid character",s)}else{if(q===3)k.$2(m,s)
o=A.e8(B.a.j(a,r,s),null)
if(o>255)k.$2(l,r)
n=q+1
j[q]=o
r=s+1
q=n}}if(q!==3)k.$2(m,c)
o=A.e8(B.a.j(a,r,c),null)
if(o>255)k.$2(l,r)
j[q]=o
return j},
fg(a,b,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d=new A.cY(a),c=new A.cZ(d,a)
if(a.length<2)d.$2("address is too short",e)
s=A.h([],t.t)
for(r=b,q=r,p=!1,o=!1;r<a0;++r){n=a.charCodeAt(r)
if(n===58){if(r===b){++r
if(a.charCodeAt(r)!==58)d.$2("invalid start colon.",r)
q=r}if(r===q){if(p)d.$2("only one wildcard `::` is allowed",r)
s.push(-1)
p=!0}else s.push(c.$2(q,r))
q=r+1}else if(n===46)o=!0}if(s.length===0)d.$2("too few parts",e)
m=q===a0
l=B.b.ga_(s)
if(m&&l!==-1)d.$2("expected a part after last `:`",a0)
if(!m)if(!o)s.push(c.$2(q,a0))
else{k=A.ia(a,q,a0)
s.push((k[0]<<8|k[1])>>>0)
s.push((k[2]<<8|k[3])>>>0)}if(p){if(s.length>7)d.$2("an address with a wildcard must have less than 7 parts",e)}else if(s.length!==8)d.$2("an address without a wildcard must contain exactly 8 parts",e)
j=new Uint8Array(16)
for(l=s.length,i=9-l,r=0,h=0;r<l;++r){g=s[r]
if(g===-1)for(f=0;f<i;++f){j[h]=0
j[h+1]=0
h+=2}else{j[h]=B.c.V(g,8)
j[h+1]=g&255
h+=2}}return j},
es(a,b,c,d,e,f,g){return new A.bn(a,b,c,d,e,f,g)},
fu(a){if(a==="http")return 80
if(a==="https")return 443
return 0},
aA(a,b,c){throw A.a(A.z(c,a,b))},
iG(a,b){if(a!=null&&a===A.fu(b))return null
return a},
iE(a,b,c,d){var s,r,q,p,o,n
if(b===c)return""
if(a.charCodeAt(b)===91){s=c-1
if(a.charCodeAt(s)!==93)A.aA(a,b,"Missing end `]` to match `[` in host")
r=b+1
q=A.iB(a,r,s)
if(q<s){p=q+1
o=A.fz(a,B.a.v(a,"25",p)?q+3:p,s,"%25")}else o=""
A.fg(a,r,q)
return B.a.j(a,b,q).toLowerCase()+o+"]"}for(n=b;n<c;++n)if(a.charCodeAt(n)===58){q=B.a.Z(a,"%",b)
q=q>=b&&q<c?q:c
if(q<c){p=q+1
o=A.fz(a,B.a.v(a,"25",p)?q+3:p,c,"%25")}else o=""
A.fg(a,b,q)
return"["+B.a.j(a,b,q)+o+"]"}return A.iM(a,b,c)},
iB(a,b,c){var s=B.a.Z(a,"%",b)
return s>=b&&s<c?s:c},
fz(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i=d!==""?new A.y(d):null
for(s=b,r=s,q=!0;s<c;){p=a.charCodeAt(s)
if(p===37){o=A.ev(a,s,!0)
n=o==null
if(n&&q){s+=3
continue}if(i==null)i=new A.y("")
m=i.a+=B.a.j(a,r,s)
if(n)o=B.a.j(a,s,s+3)
else if(o==="%")A.aA(a,s,"ZoneID should not contain % anymore")
i.a=m+o
s+=3
r=s
q=!0}else if(p<127&&(B.h[p>>>4]&1<<(p&15))!==0){if(q&&65<=p&&90>=p){if(i==null)i=new A.y("")
if(r<s){i.a+=B.a.j(a,r,s)
r=s}q=!1}++s}else{if((p&64512)===55296&&s+1<c){l=a.charCodeAt(s+1)
if((l&64512)===56320){p=(p&1023)<<10|l&1023|65536
k=2}else k=1}else k=1
j=B.a.j(a,r,s)
if(i==null){i=new A.y("")
n=i}else n=i
n.a+=j
m=A.et(p)
n.a+=m
s+=k
r=s}}if(i==null)return B.a.j(a,b,c)
if(r<c){j=B.a.j(a,r,c)
i.a+=j}n=i.a
return n.charCodeAt(0)==0?n:n},
iM(a,b,c){var s,r,q,p,o,n,m,l,k,j,i
for(s=b,r=s,q=null,p=!0;s<c;){o=a.charCodeAt(s)
if(o===37){n=A.ev(a,s,!0)
m=n==null
if(m&&p){s+=3
continue}if(q==null)q=new A.y("")
l=B.a.j(a,r,s)
if(!p)l=l.toLowerCase()
k=q.a+=l
if(m){n=B.a.j(a,s,s+3)
j=3}else if(n==="%"){n="%25"
j=1}else j=3
q.a=k+n
s+=j
r=s
p=!0}else if(o<127&&(B.a9[o>>>4]&1<<(o&15))!==0){if(p&&65<=o&&90>=o){if(q==null)q=new A.y("")
if(r<s){q.a+=B.a.j(a,r,s)
r=s}p=!1}++s}else if(o<=93&&(B.r[o>>>4]&1<<(o&15))!==0)A.aA(a,s,"Invalid character")
else{if((o&64512)===55296&&s+1<c){i=a.charCodeAt(s+1)
if((i&64512)===56320){o=(o&1023)<<10|i&1023|65536
j=2}else j=1}else j=1
l=B.a.j(a,r,s)
if(!p)l=l.toLowerCase()
if(q==null){q=new A.y("")
m=q}else m=q
m.a+=l
k=A.et(o)
m.a+=k
s+=j
r=s}}if(q==null)return B.a.j(a,b,c)
if(r<c){l=B.a.j(a,r,c)
if(!p)l=l.toLowerCase()
q.a+=l}m=q.a
return m.charCodeAt(0)==0?m:m},
iJ(a,b,c){var s,r,q
if(b===c)return""
if(!A.fw(a.charCodeAt(b)))A.aA(a,b,"Scheme not starting with alphabetic character")
for(s=b,r=!1;s<c;++s){q=a.charCodeAt(s)
if(!(q<128&&(B.o[q>>>4]&1<<(q&15))!==0))A.aA(a,s,"Illegal scheme character")
if(65<=q&&q<=90)r=!0}a=B.a.j(a,b,c)
return A.iA(r?a.toLowerCase():a)},
iA(a){if(a==="http")return"http"
if(a==="file")return"file"
if(a==="https")return"https"
if(a==="package")return"package"
return a},
iK(a,b,c){return A.bo(a,b,c,B.a8,!1,!1)},
iF(a,b,c,d,e,f){var s,r=e==="file",q=r||f
if(a==null)return r?"/":""
else s=A.bo(a,b,c,B.p,!0,!0)
if(s.length===0){if(r)return"/"}else if(q&&!B.a.u(s,"/"))s="/"+s
return A.iL(s,e,f)},
iL(a,b,c){var s=b.length===0
if(s&&!c&&!B.a.u(a,"/")&&!B.a.u(a,"\\"))return A.iN(a,!s||c)
return A.iO(a)},
eu(a,b,c,d){if(a!=null){if(d!=null)throw A.a(A.a_("Both query and queryParameters specified",null))
return A.bo(a,b,c,B.f,!0,!1)}if(d==null)return null
return A.iH(d)},
iI(a){var s={},r=new A.y("")
s.a=""
a.C(0,new A.dB(new A.dC(s,r)))
s=r.a
return s.charCodeAt(0)==0?s:s},
iD(a,b,c){return A.bo(a,b,c,B.f,!0,!1)},
ev(a,b,c){var s,r,q,p,o,n=b+2
if(n>=a.length)return"%"
s=a.charCodeAt(b+1)
r=a.charCodeAt(n)
q=A.e0(s)
p=A.e0(r)
if(q<0||p<0)return"%"
o=q*16+p
if(o<127&&(B.h[B.c.V(o,4)]&1<<(o&15))!==0)return A.Q(c&&65<=o&&90>=o?(o|32)>>>0:o)
if(s>=97||r>=97)return B.a.j(a,b,b+3).toUpperCase()
return null},
et(a){var s,r,q,p,o,n="0123456789ABCDEF"
if(a<128){s=new Uint8Array(3)
s[0]=37
s[1]=n.charCodeAt(a>>>4)
s[2]=n.charCodeAt(a&15)}else{if(a>2047)if(a>65535){r=240
q=4}else{r=224
q=3}else{r=192
q=2}s=new Uint8Array(3*q)
for(p=0;--q,q>=0;r=128){o=B.c.bv(a,6*q)&63|r
s[p]=37
s[p+1]=n.charCodeAt(o>>>4)
s[p+2]=n.charCodeAt(o&15)
p+=3}}return A.fc(s,0,null)},
bo(a,b,c,d,e,f){var s=A.fy(a,b,c,d,e,f)
return s==null?B.a.j(a,b,c):s},
fy(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i=null
for(s=!e,r=b,q=r,p=i;r<c;){o=a.charCodeAt(r)
if(o<127&&(d[o>>>4]&1<<(o&15))!==0)++r
else{if(o===37){n=A.ev(a,r,!1)
if(n==null){r+=3
continue}if("%"===n){n="%25"
m=1}else m=3}else if(o===92&&f){n="/"
m=1}else if(s&&o<=93&&(B.r[o>>>4]&1<<(o&15))!==0){A.aA(a,r,"Invalid character")
m=i
n=m}else{if((o&64512)===55296){l=r+1
if(l<c){k=a.charCodeAt(l)
if((k&64512)===56320){o=(o&1023)<<10|k&1023|65536
m=2}else m=1}else m=1}else m=1
n=A.et(o)}if(p==null){p=new A.y("")
l=p}else l=p
j=l.a+=B.a.j(a,q,r)
l.a=j+A.i(n)
r+=m
q=r}}if(p==null)return i
if(q<c){s=B.a.j(a,q,c)
p.a+=s}s=p.a
return s.charCodeAt(0)==0?s:s},
fx(a){if(B.a.u(a,"."))return!0
return B.a.aU(a,"/.")!==-1},
iO(a){var s,r,q,p,o,n
if(!A.fx(a))return a
s=A.h([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(J.F(n,"..")){if(s.length!==0){s.pop()
if(s.length===0)s.push("")}p=!0}else{p="."===n
if(!p)s.push(n)}}if(p)s.push("")
return B.b.aY(s,"/")},
iN(a,b){var s,r,q,p,o,n
if(!A.fx(a))return!b?A.fv(a):a
s=A.h([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(".."===n){p=s.length!==0&&B.b.ga_(s)!==".."
if(p)s.pop()
else s.push("..")}else{p="."===n
if(!p)s.push(n)}}r=s.length
if(r!==0)r=r===1&&s[0].length===0
else r=!0
if(r)return"./"
if(p||B.b.ga_(s)==="..")s.push("")
if(!b)s[0]=A.fv(s[0])
return B.b.aY(s,"/")},
fv(a){var s,r,q=a.length
if(q>=2&&A.fw(a.charCodeAt(0)))for(s=1;s<q;++s){r=a.charCodeAt(s)
if(r===58)return B.a.j(a,0,s)+"%3A"+B.a.K(a,s+1)
if(r>127||(B.o[r>>>4]&1<<(r&15))===0)break}return a},
iC(a,b){var s,r,q
for(s=0,r=0;r<2;++r){q=a.charCodeAt(b+r)
if(48<=q&&q<=57)s=s*16+q-48
else{q|=32
if(97<=q&&q<=102)s=s*16+q-87
else throw A.a(A.a_("Invalid URL encoding",null))}}return s},
ew(a,b,c,d,e){var s,r,q,p,o=b
while(!0){if(!(o<c)){s=!0
break}r=a.charCodeAt(o)
if(r<=127)if(r!==37)q=r===43
else q=!0
else q=!0
if(q){s=!1
break}++o}if(s)if(B.e===d)return B.a.j(a,b,c)
else p=new A.bB(B.a.j(a,b,c))
else{p=A.h([],t.t)
for(q=a.length,o=b;o<c;++o){r=a.charCodeAt(o)
if(r>127)throw A.a(A.a_("Illegal percent encoding in URI",null))
if(r===37){if(o+3>q)throw A.a(A.a_("Truncated URI",null))
p.push(A.iC(a,o+1))
o+=2}else if(r===43)p.push(32)
else p.push(r)}}return B.ap.I(p)},
fw(a){var s=a|32
return 97<=s&&s<=122},
ff(a,b,c){var s,r,q,p,o,n,m,l,k="Invalid MIME type",j=A.h([b-1],t.t)
for(s=a.length,r=b,q=-1,p=null;r<s;++r){p=a.charCodeAt(r)
if(p===44||p===59)break
if(p===47){if(q<0){q=r
continue}throw A.a(A.z(k,a,r))}}if(q<0&&r>b)throw A.a(A.z(k,a,r))
for(;p!==44;){j.push(r);++r
for(o=-1;r<s;++r){p=a.charCodeAt(r)
if(p===61){if(o<0)o=r}else if(p===59||p===44)break}if(o>=0)j.push(o)
else{n=B.b.ga_(j)
if(p!==44||r!==n+7||!B.a.v(a,"base64",n+1))throw A.a(A.z("Expecting '='",a,r))
break}}j.push(r)
m=r+1
if((j.length&1)===1)a=B.x.bP(a,m,s)
else{l=A.fy(a,m,s,B.f,!0,!1)
if(l!=null)a=B.a.J(a,m,s,l)}return new A.cW(a,j,c)},
j_(){var s,r,q,p,o,n="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~!$&'()*+,;=",m=".",l=":",k="/",j="\\",i="?",h="#",g="/\\",f=J.eX(22,t.D)
for(s=0;s<22;++s)f[s]=new Uint8Array(96)
r=new A.dP(f)
q=new A.dQ()
p=new A.dR()
o=r.$2(0,225)
q.$3(o,n,1)
q.$3(o,m,14)
q.$3(o,l,34)
q.$3(o,k,3)
q.$3(o,j,227)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(14,225)
q.$3(o,n,1)
q.$3(o,m,15)
q.$3(o,l,34)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(15,225)
q.$3(o,n,1)
q.$3(o,"%",225)
q.$3(o,l,34)
q.$3(o,k,9)
q.$3(o,j,233)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(1,225)
q.$3(o,n,1)
q.$3(o,l,34)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(2,235)
q.$3(o,n,139)
q.$3(o,k,131)
q.$3(o,j,131)
q.$3(o,m,146)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(3,235)
q.$3(o,n,11)
q.$3(o,k,68)
q.$3(o,j,68)
q.$3(o,m,18)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(4,229)
q.$3(o,n,5)
p.$3(o,"AZ",229)
q.$3(o,l,102)
q.$3(o,"@",68)
q.$3(o,"[",232)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(5,229)
q.$3(o,n,5)
p.$3(o,"AZ",229)
q.$3(o,l,102)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(6,231)
p.$3(o,"19",7)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(7,231)
p.$3(o,"09",7)
q.$3(o,"@",68)
q.$3(o,k,138)
q.$3(o,j,138)
q.$3(o,i,172)
q.$3(o,h,205)
q.$3(r.$2(8,8),"]",5)
o=r.$2(9,235)
q.$3(o,n,11)
q.$3(o,m,16)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(16,235)
q.$3(o,n,11)
q.$3(o,m,17)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(17,235)
q.$3(o,n,11)
q.$3(o,k,9)
q.$3(o,j,233)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(10,235)
q.$3(o,n,11)
q.$3(o,m,18)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(18,235)
q.$3(o,n,11)
q.$3(o,m,19)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(19,235)
q.$3(o,n,11)
q.$3(o,g,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(11,235)
q.$3(o,n,11)
q.$3(o,k,10)
q.$3(o,j,234)
q.$3(o,i,172)
q.$3(o,h,205)
o=r.$2(12,236)
q.$3(o,n,12)
q.$3(o,i,12)
q.$3(o,h,205)
o=r.$2(13,237)
q.$3(o,n,13)
q.$3(o,i,13)
p.$3(r.$2(20,245),"az",21)
o=r.$2(21,245)
p.$3(o,"az",21)
p.$3(o,"09",21)
q.$3(o,"+-.",21)
return f},
fV(a,b,c,d,e){var s,r,q,p,o=$.hq()
for(s=b;s<c;++s){r=o[d]
q=a.charCodeAt(s)^96
p=r[q>95?31:q]
d=p&31
e[p>>>5]=s}return d},
cM:function cM(a,b){this.a=a
this.b=b},
dD:function dD(a){this.a=a},
d8:function d8(){},
k:function k(){},
bx:function bx(a){this.a=a},
R:function R(){},
G:function G(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
b2:function b2(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bF:function bF(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bV:function bV(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
c2:function c2(a){this.a=a},
c_:function c_(a){this.a=a},
b5:function b5(a){this.a=a},
bD:function bD(a){this.a=a},
bW:function bW(){},
b4:function b4(){},
d9:function d9(a){this.a=a},
cw:function cw(a,b,c){this.a=a
this.b=b
this.c=c},
n:function n(){},
u:function u(){},
l:function l(){},
cj:function cj(){},
y:function y(a){this.a=a},
d_:function d_(a){this.a=a},
cX:function cX(a){this.a=a},
cY:function cY(a){this.a=a},
cZ:function cZ(a,b){this.a=a
this.b=b},
bn:function bn(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.z=_.y=_.w=$},
dC:function dC(a,b){this.a=a
this.b=b},
dB:function dB(a){this.a=a},
cW:function cW(a,b,c){this.a=a
this.b=b
this.c=c},
dP:function dP(a){this.a=a},
dQ:function dQ(){},
dR:function dR(){},
ch:function ch(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=null},
c9:function c9(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.z=_.y=_.w=$},
iY(a){var s,r=a.$dart_jsFunction
if(r!=null)return r
s=function(b,c){return function(){return b(c,Array.prototype.slice.apply(arguments))}}(A.iW,a)
s[$.eK()]=a
a.$dart_jsFunction=s
return s},
iW(a,b){return A.i1(a,b,null)},
ab(a){if(typeof a=="function")return a
else return A.iY(a)},
eb(a,b){var s=new A.v($.r,b.i("v<0>")),r=new A.b7(s,b.i("b7<0>"))
a.then(A.aF(new A.ec(r),1),A.aF(new A.ed(r),1))
return s},
ec:function ec(a){this.a=a},
ed:function ed(a){this.a=a},
cN:function cN(a){this.a=a},
m:function m(a,b){this.a=a
this.b=b},
hL(a){var s,r,q,p,o,n,m,l,k="enclosedBy"
if(a.k(0,k)!=null){s=t.a.a(a.k(0,k))
r=new A.cu(A.fG(s.k(0,"name")),B.q[A.fE(s.k(0,"kind"))],A.fG(s.k(0,"href")))}else r=null
q=a.k(0,"name")
p=a.k(0,"qualifiedName")
o=A.fF(a.k(0,"packageRank"))
if(o==null)o=0
n=a.k(0,"href")
m=B.q[A.fE(a.k(0,"kind"))]
l=A.fF(a.k(0,"overriddenDepth"))
if(l==null)l=0
return new A.w(q,p,o,m,n,l,a.k(0,"desc"),r)},
A:function A(a,b){this.a=a
this.b=b},
cz:function cz(a){this.a=a},
cC:function cC(a,b){this.a=a
this.b=b},
cA:function cA(){},
cB:function cB(){},
w:function w(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
cu:function cu(a,b,c){this.a=a
this.b=b
this.c=c},
jN(){var s=self,r=s.document.getElementById("search-box"),q=s.document.getElementById("search-body"),p=s.document.getElementById("search-sidebar")
A.eb(s.window.fetch($.bw()+"index.json"),t.m).ar(new A.e5(new A.e6(r,q,p),r,q,p),t.P)},
eo(a){var s=A.h([],t.O),r=A.h([],t.M)
return new A.ds(a,A.c4(self.window.location.href),s,r)},
iZ(a,b){var s,r,q,p,o,n,m,l,k=self,j=k.document.createElement("div"),i=b.e
if(i==null)i=""
j.setAttribute("data-href",i)
j.classList.add("tt-suggestion")
s=k.document.createElement("span")
s.classList.add("tt-suggestion-title")
s.innerHTML=A.ex(b.a+" "+b.d.h(0).toLowerCase(),a)
j.appendChild(s)
r=b.w
i=r!=null
if(i){q=k.document.createElement("span")
q.classList.add("tt-suggestion-container")
q.innerHTML="(in "+A.ex(r.a,a)+")"
j.appendChild(q)}p=b.r
if(p!=null&&p.length!==0){o=k.document.createElement("blockquote")
o.classList.add("one-line-description")
q=k.document.createElement("textarea")
q.innerHTML=p
o.setAttribute("title",q.value)
o.innerHTML=A.ex(p,a)
j.appendChild(o)}q=t.g
j.addEventListener("mousedown",q.a(A.ab(new A.dN())))
j.addEventListener("click",q.a(A.ab(new A.dO(b))))
if(i){i=r.a
q=r.b.h(0)
n=r.c
m=k.document.createElement("div")
m.classList.add("tt-container")
l=k.document.createElement("p")
l.textContent="Results from "
l.classList.add("tt-container-text")
k=k.document.createElement("a")
k.setAttribute("href",n)
k.innerHTML=i+" "+q
l.appendChild(k)
m.appendChild(l)
A.jm(m,j)}return j},
jm(a,b){var s,r=a.innerHTML
if(r.length===0)return
s=$.bq.k(0,r)
if(s!=null)s.appendChild(b)
else{a.appendChild(b)
$.bq.q(0,r,a)}},
ex(a,b){return A.k3(a,A.f6(b,!1),new A.dS(),null)},
dT:function dT(){},
e6:function e6(a,b,c){this.a=a
this.b=b
this.c=c},
e5:function e5(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ds:function ds(a,b,c,d){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=$
_.f=null
_.r=""
_.w=c
_.x=d
_.y=-1},
dt:function dt(a){this.a=a},
du:function du(a,b){this.a=a
this.b=b},
dv:function dv(a,b){this.a=a
this.b=b},
dw:function dw(a,b){this.a=a
this.b=b},
dx:function dx(a,b){this.a=a
this.b=b},
dN:function dN(){},
dO:function dO(a){this.a=a},
dS:function dS(){},
j6(){var s=self,r=s.document.getElementById("sidenav-left-toggle"),q=s.document.querySelector(".sidebar-offcanvas-left"),p=s.document.getElementById("overlay-under-drawer"),o=t.g.a(A.ab(new A.dU(q,p)))
if(p!=null)p.addEventListener("click",o)
if(r!=null)r.addEventListener("click",o)},
j5(){var s,r,q,p,o=self,n=o.document.body
if(n==null)return
s=n.getAttribute("data-using-base-href")
if(s==null)return
if(s!=="true"){r=n.getAttribute("data-base-href")
if(r==null)return
q=r}else q=""
p=o.document.getElementById("dartdoc-main-content")
if(p==null)return
A.fR(q,p.getAttribute("data-above-sidebar"),o.document.getElementById("dartdoc-sidebar-left-content"))
A.fR(q,p.getAttribute("data-below-sidebar"),o.document.getElementById("dartdoc-sidebar-right"))},
fR(a,b,c){if(b==null||b.length===0||c==null)return
A.eb(self.window.fetch(a+A.i(b)),t.m).ar(new A.dV(c,a),t.P)},
fY(a,b){var s,r,q,p
if(b.nodeName.toLowerCase()==="a"){s=b.getAttribute("href")
if(s!=null)if(!A.c4(s).gaX())b.href=a+s}r=b.childNodes
for(q=0;q<r.length;++q){p=r.item(q)
if(p!=null)A.fY(a,p)}},
dU:function dU(a,b){this.a=a
this.b=b},
dV:function dV(a,b){this.a=a
this.b=b},
jO(){var s,r,q,p=self,o=p.document.body
if(o==null)return
s=p.document.getElementById("theme")
if(s==null)s=t.m.a(s)
r=new A.e7(s,o)
s.addEventListener("change",t.g.a(A.ab(new A.e4(r))))
q=p.window.localStorage.getItem("colorTheme")
if(q!=null){s.checked=q==="true"
r.$0()}},
e7:function e7(a,b){this.a=a
this.b=b},
e4:function e4(a){this.a=a},
jZ(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
k4(a){A.h8(new A.aV("Field '"+a+"' has been assigned during initialization."),new Error())},
bv(){A.h8(new A.aV("Field '' has been assigned during initialization."),new Error())},
jW(){A.j5()
A.j6()
A.jN()
var s=self.hljs
if(s!=null)s.highlightAll()
A.jO()}},B={}
var w=[A,J,B]
var $={}
A.eh.prototype={}
J.bG.prototype={
F(a,b){return a===b},
gn(a){return A.bY(a)},
h(a){return"Instance of '"+A.cQ(a)+"'"},
b_(a,b){throw A.a(A.f1(a,b))},
gt(a){return A.an(A.ey(this))}}
J.bH.prototype={
h(a){return String(a)},
gn(a){return a?519018:218159},
gt(a){return A.an(t.y)},
$ij:1}
J.aQ.prototype={
F(a,b){return null==b},
h(a){return"null"},
gn(a){return 0},
$ij:1,
$iu:1}
J.aT.prototype={$ip:1}
J.a2.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.bX.prototype={}
J.ax.prototype={}
J.a1.prototype={
h(a){var s=a[$.eK()]
if(s==null)return this.be(a)
return"JavaScript function for "+J.aq(s)}}
J.aS.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.aU.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.o.prototype={
X(a,b){return new A.M(a,A.am(a).i("@<1>").A(b).i("M<1,2>"))},
ad(a,b){if(!!a.fixed$length)A.aH(A.T("add"))
a.push(b)},
aI(a,b){var s
if(!!a.fixed$length)A.aH(A.T("addAll"))
if(Array.isArray(b)){this.bg(a,b)
return}for(s=J.L(b);s.m();)a.push(s.gp())},
bg(a,b){var s,r=b.length
if(r===0)return
if(a===b)throw A.a(A.as(a))
for(s=0;s<r;++s)a.push(b[s])},
Y(a){if(!!a.fixed$length)A.aH(A.T("clear"))
a.length=0},
aY(a,b){var s,r=A.f0(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)r[s]=A.i(a[s])
return r.join(b)},
bG(a,b,c){var s,r,q=a.length
for(s=b,r=0;r<q;++r){s=c.$2(s,a[r])
if(a.length!==q)throw A.a(A.as(a))}return s},
bH(a,b,c){return this.bG(a,b,c,t.z)},
E(a,b){return a[b]},
bd(a,b,c){var s=a.length
if(b>s)throw A.a(A.H(b,0,s,"start",null))
if(c<b||c>s)throw A.a(A.H(c,b,s,"end",null))
if(b===c)return A.h([],A.am(a))
return A.h(a.slice(b,c),A.am(a))},
gbF(a){if(a.length>0)return a[0]
throw A.a(A.eV())},
ga_(a){var s=a.length
if(s>0)return a[s-1]
throw A.a(A.eV())},
bc(a,b){var s,r,q,p,o
if(!!a.immutable$list)A.aH(A.T("sort"))
s=a.length
if(s<2)return
if(b==null)b=J.ja()
if(s===2){r=a[0]
q=a[1]
if(b.$2(r,q)>0){a[0]=q
a[1]=r}return}if(A.am(a).c.b(null)){for(p=0,o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}}else p=0
a.sort(A.aF(b,2))
if(p>0)this.bt(a,p)},
bt(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
h(a){return A.eW(a,"[","]")},
gB(a){return new J.ar(a,a.length,A.am(a).i("ar<1>"))},
gn(a){return A.bY(a)},
gl(a){return a.length},
k(a,b){if(!(b>=0&&b<a.length))throw A.a(A.eF(a,b))
return a[b]},
q(a,b,c){if(!!a.immutable$list)A.aH(A.T("indexed set"))
if(!(b>=0&&b<a.length))throw A.a(A.eF(a,b))
a[b]=c},
$ic:1,
$if:1}
J.cF.prototype={}
J.ar.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
m(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.a(A.co(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0}}
J.aR.prototype={
aL(a,b){var s
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gam(b)
if(this.gam(a)===s)return 0
if(this.gam(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gam(a){return a===0?1/a<0:a<0},
h(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gn(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
a1(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
bw(a,b){return(a|0)===a?a/b|0:this.bx(a,b)},
bx(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.a(A.T("Result of truncating division is "+A.i(s)+": "+A.i(a)+" ~/ "+b))},
V(a,b){var s
if(a>0)s=this.aF(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
bv(a,b){if(0>b)throw A.a(A.jz(b))
return this.aF(a,b)},
aF(a,b){return b>31?0:a>>>b},
gt(a){return A.an(t.H)},
$it:1}
J.aP.prototype={
gt(a){return A.an(t.S)},
$ij:1,
$ib:1}
J.bI.prototype={
gt(a){return A.an(t.i)},
$ij:1}
J.ai.prototype={
b6(a,b){return a+b},
J(a,b,c,d){var s=A.b3(b,c,a.length)
return a.substring(0,b)+d+a.substring(s)},
v(a,b,c){var s
if(c<0||c>a.length)throw A.a(A.H(c,0,a.length,null,null))
s=c+b.length
if(s>a.length)return!1
return b===a.substring(c,s)},
u(a,b){return this.v(a,b,0)},
j(a,b,c){return a.substring(b,A.b3(b,c,a.length))},
K(a,b){return this.j(a,b,null)},
b9(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.a(B.F)
for(s=a,r="";!0;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
Z(a,b,c){var s
if(c<0||c>a.length)throw A.a(A.H(c,0,a.length,null,null))
s=a.indexOf(b,c)
return s},
aU(a,b){return this.Z(a,b,0)},
ag(a,b){return A.k2(a,b,0)},
aL(a,b){var s
if(a===b)s=0
else s=a<b?-1:1
return s},
h(a){return a},
gn(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gt(a){return A.an(t.N)},
gl(a){return a.length},
$ij:1,
$id:1}
A.a8.prototype={
gB(a){var s=A.E(this)
return new A.bA(J.L(this.gN()),s.i("@<1>").A(s.y[1]).i("bA<1,2>"))},
gl(a){return J.aI(this.gN())},
E(a,b){return A.E(this).y[1].a(J.ef(this.gN(),b))},
h(a){return J.aq(this.gN())}}
A.bA.prototype={
m(){return this.a.m()},
gp(){return this.$ti.y[1].a(this.a.gp())}}
A.af.prototype={
gN(){return this.a}}
A.b9.prototype={$ic:1}
A.b8.prototype={
k(a,b){return this.$ti.y[1].a(J.hr(this.a,b))},
q(a,b,c){J.hs(this.a,b,this.$ti.c.a(c))},
$ic:1,
$if:1}
A.M.prototype={
X(a,b){return new A.M(this.a,this.$ti.i("@<1>").A(b).i("M<1,2>"))},
gN(){return this.a}}
A.aV.prototype={
h(a){return"LateInitializationError: "+this.a}}
A.bB.prototype={
gl(a){return this.a.length},
k(a,b){return this.a.charCodeAt(b)}}
A.cR.prototype={}
A.c.prototype={}
A.J.prototype={
gB(a){var s=this
return new A.au(s,s.gl(s),A.E(s).i("au<J.E>"))}}
A.au.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
m(){var s,r=this,q=r.a,p=J.ao(q),o=p.gl(q)
if(r.b!==o)throw A.a(A.as(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.E(q,s);++r.c
return!0}}
A.aj.prototype={
gB(a){var s=A.E(this)
return new A.av(J.L(this.a),this.b,s.i("@<1>").A(s.y[1]).i("av<1,2>"))},
gl(a){return J.aI(this.a)},
E(a,b){return this.b.$1(J.ef(this.a,b))}}
A.aM.prototype={$ic:1}
A.av.prototype={
m(){var s=this,r=s.b
if(r.m()){s.a=s.c.$1(r.gp())
return!0}s.a=null
return!1},
gp(){var s=this.a
return s==null?this.$ti.y[1].a(s):s}}
A.ak.prototype={
gl(a){return J.aI(this.a)},
E(a,b){return this.b.$1(J.ef(this.a,b))}}
A.aO.prototype={}
A.c1.prototype={
q(a,b,c){throw A.a(A.T("Cannot modify an unmodifiable list"))}}
A.ay.prototype={}
A.a5.prototype={
gn(a){var s=this._hashCode
if(s!=null)return s
s=664597*B.a.gn(this.a)&536870911
this._hashCode=s
return s},
h(a){return'Symbol("'+this.a+'")'},
F(a,b){if(b==null)return!1
return b instanceof A.a5&&this.a===b.a},
$ib6:1}
A.bp.prototype={}
A.cg.prototype={$r:"+item,matchPosition(1,2)",$s:1}
A.aL.prototype={}
A.aK.prototype={
h(a){return A.ek(this)},
q(a,b,c){A.hG()},
$ix:1}
A.ah.prototype={
gl(a){return this.b.length},
gbq(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
H(a){if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
k(a,b){if(!this.H(b))return null
return this.b[this.a[b]]},
C(a,b){var s,r,q=this.gbq(),p=this.b
for(s=q.length,r=0;r<s;++r)b.$2(q[r],p[r])}}
A.cD.prototype={
gbN(){var s=this.a
if(s instanceof A.a5)return s
return this.a=new A.a5(s)},
gbQ(){var s,r,q,p,o,n=this
if(n.c===1)return B.t
s=n.d
r=J.ao(s)
q=r.gl(s)-J.aI(n.e)-n.f
if(q===0)return B.t
p=[]
for(o=0;o<q;++o)p.push(r.k(s,o))
return J.eY(p)},
gbO(){var s,r,q,p,o,n,m,l,k=this
if(k.c!==0)return B.u
s=k.e
r=J.ao(s)
q=r.gl(s)
p=k.d
o=J.ao(p)
n=o.gl(p)-q-k.f
if(q===0)return B.u
m=new A.N(t.B)
for(l=0;l<q;++l)m.q(0,new A.a5(r.k(s,l)),o.k(p,n+l))
return new A.aL(m,t.Z)}}
A.cP.prototype={
$2(a,b){var s=this.a
s.b=s.b+"$"+a
this.b.push(a)
this.c.push(b);++s.a},
$S:2}
A.cU.prototype={
D(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.b1.prototype={
h(a){return"Null check operator used on a null value"}}
A.bJ.prototype={
h(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.c0.prototype={
h(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.cO.prototype={
h(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.aN.prototype={}
A.bg.prototype={
h(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$ia4:1}
A.ag.prototype={
h(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.h9(r==null?"unknown":r)+"'"},
gbZ(){return this},
$C:"$1",
$R:1,
$D:null}
A.cs.prototype={$C:"$0",$R:0}
A.ct.prototype={$C:"$2",$R:2}
A.cT.prototype={}
A.cS.prototype={
h(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.h9(s)+"'"}}
A.aJ.prototype={
F(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.aJ))return!1
return this.$_target===b.$_target&&this.a===b.a},
gn(a){return(A.h5(this.a)^A.bY(this.$_target))>>>0},
h(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.cQ(this.a)+"'")}}
A.c8.prototype={
h(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.bZ.prototype={
h(a){return"RuntimeError: "+this.a}}
A.dp.prototype={}
A.N.prototype={
gl(a){return this.a},
gO(){return new A.O(this,A.E(this).i("O<1>"))},
gb5(){var s=A.E(this)
return A.hW(new A.O(this,s.i("O<1>")),new A.cG(this),s.c,s.y[1])},
H(a){var s=this.b
if(s==null)return!1
return s[a]!=null},
k(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.bL(b)},
bL(a){var s,r,q=this.d
if(q==null)return null
s=q[this.aV(a)]
r=this.aW(s,a)
if(r<0)return null
return s[r].b},
q(a,b,c){var s,r,q,p,o,n,m=this
if(typeof b=="string"){s=m.b
m.av(s==null?m.b=m.a8():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=m.c
m.av(r==null?m.c=m.a8():r,b,c)}else{q=m.d
if(q==null)q=m.d=m.a8()
p=m.aV(b)
o=q[p]
if(o==null)q[p]=[m.a9(b,c)]
else{n=m.aW(o,b)
if(n>=0)o[n].b=c
else o.push(m.a9(b,c))}}},
Y(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.aC()}},
C(a,b){var s=this,r=s.e,q=s.r
for(;r!=null;){b.$2(r.a,r.b)
if(q!==s.r)throw A.a(A.as(s))
r=r.c}},
av(a,b,c){var s=a[b]
if(s==null)a[b]=this.a9(b,c)
else s.b=c},
aC(){this.r=this.r+1&1073741823},
a9(a,b){var s=this,r=new A.cJ(a,b)
if(s.e==null)s.e=s.f=r
else s.f=s.f.c=r;++s.a
s.aC()
return r},
aV(a){return J.Z(a)&1073741823},
aW(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.F(a[r].a,b))return r
return-1},
h(a){return A.ek(this)},
a8(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s}}
A.cG.prototype={
$1(a){var s=this.a,r=s.k(0,a)
return r==null?A.E(s).y[1].a(r):r},
$S(){return A.E(this.a).i("2(1)")}}
A.cJ.prototype={}
A.O.prototype={
gl(a){return this.a.a},
gB(a){var s=this.a,r=new A.bK(s,s.r)
r.c=s.e
return r}}
A.bK.prototype={
gp(){return this.d},
m(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.a(A.as(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}}}
A.e1.prototype={
$1(a){return this.a(a)},
$S:10}
A.e2.prototype={
$2(a,b){return this.a(a,b)},
$S:11}
A.e3.prototype={
$1(a){return this.a(a)},
$S:12}
A.bf.prototype={
h(a){return this.aH(!1)},
aH(a){var s,r,q,p,o,n=this.bo(),m=this.aB(),l=(a?""+"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
o=m[q]
l=a?l+A.f4(o):l+A.i(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
bo(){var s,r=this.$s
for(;$.dn.length<=r;)$.dn.push(null)
s=$.dn[r]
if(s==null){s=this.bj()
$.dn[r]=s}return s},
bj(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.K,j=J.eX(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
j[q]=r[s]}}return J.eY(A.hV(j,!1,k))}}
A.cf.prototype={
aB(){return[this.a,this.b]},
F(a,b){if(b==null)return!1
return b instanceof A.cf&&this.$s===b.$s&&J.F(this.a,b.a)&&J.F(this.b,b.b)},
gn(a){return A.hZ(this.$s,this.a,this.b,B.i)}}
A.cE.prototype={
h(a){return"RegExp/"+this.a+"/"+this.b.flags},
gbr(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.eZ(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,!0)},
bn(a,b){var s,r=this.gbr()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.ce(s)}}
A.ce.prototype={
gbD(){var s=this.b
return s.index+s[0].length},
k(a,b){return this.b[b]},
$icL:1,
$iel:1}
A.d3.prototype={
gp(){var s=this.d
return s==null?t.F.a(s):s},
m(){var s,r,q,p,o,n=this,m=n.b
if(m==null)return!1
s=n.c
r=m.length
if(s<=r){q=n.a
p=q.bn(m,s)
if(p!=null){n.d=p
o=p.gbD()
if(p.b.index===o){if(q.b.unicode){s=n.c
q=s+1
if(q<r){s=m.charCodeAt(s)
if(s>=55296&&s<=56319){s=m.charCodeAt(q)
s=s>=56320&&s<=57343}else s=!1}else s=!1}else s=!1
o=(s?o+1:o)+1}n.c=o
return!0}}n.b=n.d=null
return!1}}
A.bM.prototype={
gt(a){return B.ad},
$ij:1}
A.aZ.prototype={}
A.bN.prototype={
gt(a){return B.ae},
$ij:1}
A.aw.prototype={
gl(a){return a.length},
$iD:1}
A.aX.prototype={
k(a,b){A.V(b,a,a.length)
return a[b]},
q(a,b,c){A.V(b,a,a.length)
a[b]=c},
$ic:1,
$if:1}
A.aY.prototype={
q(a,b,c){A.V(b,a,a.length)
a[b]=c},
$ic:1,
$if:1}
A.bO.prototype={
gt(a){return B.af},
$ij:1}
A.bP.prototype={
gt(a){return B.ag},
$ij:1}
A.bQ.prototype={
gt(a){return B.ah},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.bR.prototype={
gt(a){return B.ai},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.bS.prototype={
gt(a){return B.aj},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.bT.prototype={
gt(a){return B.al},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.bU.prototype={
gt(a){return B.am},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.b_.prototype={
gt(a){return B.an},
gl(a){return a.length},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1}
A.b0.prototype={
gt(a){return B.ao},
gl(a){return a.length},
k(a,b){A.V(b,a,a.length)
return a[b]},
$ij:1,
$ial:1}
A.bb.prototype={}
A.bc.prototype={}
A.bd.prototype={}
A.be.prototype={}
A.I.prototype={
i(a){return A.bl(v.typeUniverse,this,a)},
A(a){return A.ft(v.typeUniverse,this,a)}}
A.cb.prototype={}
A.dA.prototype={
h(a){return A.C(this.a,null)}}
A.ca.prototype={
h(a){return this.a}}
A.bh.prototype={$iR:1}
A.d5.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:5}
A.d4.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:13}
A.d6.prototype={
$0(){this.a.$0()},
$S:6}
A.d7.prototype={
$0(){this.a.$0()},
$S:6}
A.dy.prototype={
bf(a,b){if(self.setTimeout!=null)self.setTimeout(A.aF(new A.dz(this,b),0),a)
else throw A.a(A.T("`setTimeout()` not found."))}}
A.dz.prototype={
$0(){this.b.$0()},
$S:0}
A.c5.prototype={
ae(a){var s,r=this
if(a==null)a=r.$ti.c.a(a)
if(!r.b)r.a.aw(a)
else{s=r.a
if(r.$ti.i("a0<1>").b(a))s.az(a)
else s.a4(a)}},
af(a,b){var s=this.a
if(this.b)s.L(a,b)
else s.S(a,b)}}
A.dK.prototype={
$1(a){return this.a.$2(0,a)},
$S:3}
A.dL.prototype={
$2(a,b){this.a.$2(1,new A.aN(a,b))},
$S:14}
A.dY.prototype={
$2(a,b){this.a(a,b)},
$S:15}
A.bz.prototype={
h(a){return A.i(this.a)},
$ik:1,
gR(){return this.b}}
A.c7.prototype={
af(a,b){var s
A.cn(a,"error",t.K)
s=this.a
if((s.a&30)!==0)throw A.a(A.fa("Future already completed"))
if(b==null)b=A.eN(a)
s.S(a,b)},
aM(a){return this.af(a,null)}}
A.b7.prototype={
ae(a){var s=this.a
if((s.a&30)!==0)throw A.a(A.fa("Future already completed"))
s.aw(a)}}
A.az.prototype={
bM(a){if((this.c&15)!==6)return!0
return this.b.b.aq(this.d,a.a)},
bI(a){var s,r=this.e,q=null,p=a.a,o=this.b.b
if(t.C.b(r))q=o.bU(r,p,a.b)
else q=o.aq(r,p)
try{p=q
return p}catch(s){if(t.c.b(A.ae(s))){if((this.c&1)!==0)throw A.a(A.a_("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.a(A.a_("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.v.prototype={
aE(a){this.a=this.a&1|4
this.c=a},
au(a,b,c){var s,r,q=$.r
if(q===B.d){if(b!=null&&!t.C.b(b)&&!t.v.b(b))throw A.a(A.eM(b,"onError",u.c))}else if(b!=null)b=A.jq(b,q)
s=new A.v(q,c.i("v<0>"))
r=b==null?1:3
this.a3(new A.az(s,r,a,b,this.$ti.i("@<1>").A(c).i("az<1,2>")))
return s},
ar(a,b){return this.au(a,null,b)},
aG(a,b,c){var s=new A.v($.r,c.i("v<0>"))
this.a3(new A.az(s,19,a,b,this.$ti.i("@<1>").A(c).i("az<1,2>")))
return s},
bu(a){this.a=this.a&1|16
this.c=a},
T(a){this.a=a.a&30|this.a&1
this.c=a.c},
a3(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.a3(a)
return}s.T(r)}A.aC(null,null,s.b,new A.da(s,a))}},
aa(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.aa(a)
return}n.T(s)}m.a=n.U(a)
A.aC(null,null,n.b,new A.dh(m,n))}},
ab(){var s=this.c
this.c=null
return this.U(s)},
U(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
bi(a){var s,r,q,p=this
p.a^=2
try{a.au(new A.de(p),new A.df(p),t.P)}catch(q){s=A.ae(q)
r=A.ac(q)
A.k0(new A.dg(p,s,r))}},
a4(a){var s=this,r=s.ab()
s.a=8
s.c=a
A.ba(s,r)},
L(a,b){var s=this.ab()
this.bu(A.cp(a,b))
A.ba(this,s)},
aw(a){if(this.$ti.i("a0<1>").b(a)){this.az(a)
return}this.bh(a)},
bh(a){this.a^=2
A.aC(null,null,this.b,new A.dc(this,a))},
az(a){if(this.$ti.b(a)){A.ig(a,this)
return}this.bi(a)},
S(a,b){this.a^=2
A.aC(null,null,this.b,new A.db(this,a,b))},
$ia0:1}
A.da.prototype={
$0(){A.ba(this.a,this.b)},
$S:0}
A.dh.prototype={
$0(){A.ba(this.b,this.a.a)},
$S:0}
A.de.prototype={
$1(a){var s,r,q,p=this.a
p.a^=2
try{p.a4(p.$ti.c.a(a))}catch(q){s=A.ae(q)
r=A.ac(q)
p.L(s,r)}},
$S:5}
A.df.prototype={
$2(a,b){this.a.L(a,b)},
$S:16}
A.dg.prototype={
$0(){this.a.L(this.b,this.c)},
$S:0}
A.dd.prototype={
$0(){A.fj(this.a.a,this.b)},
$S:0}
A.dc.prototype={
$0(){this.a.a4(this.b)},
$S:0}
A.db.prototype={
$0(){this.a.L(this.b,this.c)},
$S:0}
A.dk.prototype={
$0(){var s,r,q,p,o,n,m=this,l=null
try{q=m.a.a
l=q.b.b.bS(q.d)}catch(p){s=A.ae(p)
r=A.ac(p)
q=m.c&&m.b.a.c.a===s
o=m.a
if(q)o.c=m.b.a.c
else o.c=A.cp(s,r)
o.b=!0
return}if(l instanceof A.v&&(l.a&24)!==0){if((l.a&16)!==0){q=m.a
q.c=l.c
q.b=!0}return}if(l instanceof A.v){n=m.b.a
q=m.a
q.c=l.ar(new A.dl(n),t.z)
q.b=!1}},
$S:0}
A.dl.prototype={
$1(a){return this.a},
$S:17}
A.dj.prototype={
$0(){var s,r,q,p,o
try{q=this.a
p=q.a
q.c=p.b.b.aq(p.d,this.b)}catch(o){s=A.ae(o)
r=A.ac(o)
q=this.a
q.c=A.cp(s,r)
q.b=!0}},
$S:0}
A.di.prototype={
$0(){var s,r,q,p,o,n,m=this
try{s=m.a.a.c
p=m.b
if(p.a.bM(s)&&p.a.e!=null){p.c=p.a.bI(s)
p.b=!1}}catch(o){r=A.ae(o)
q=A.ac(o)
p=m.a.a.c
n=m.b
if(p.a===r)n.c=p
else n.c=A.cp(r,q)
n.b=!0}},
$S:0}
A.c6.prototype={}
A.ci.prototype={}
A.dJ.prototype={}
A.dW.prototype={
$0(){A.hI(this.a,this.b)},
$S:0}
A.dq.prototype={
bW(a){var s,r,q
try{if(B.d===$.r){a.$0()
return}A.fT(null,null,this,a)}catch(q){s=A.ae(q)
r=A.ac(q)
A.eB(s,r)}},
aJ(a){return new A.dr(this,a)},
bT(a){if($.r===B.d)return a.$0()
return A.fT(null,null,this,a)},
bS(a){return this.bT(a,t.z)},
bX(a,b){if($.r===B.d)return a.$1(b)
return A.js(null,null,this,a,b)},
aq(a,b){var s=t.z
return this.bX(a,b,s,s)},
bV(a,b,c){if($.r===B.d)return a.$2(b,c)
return A.jr(null,null,this,a,b,c)},
bU(a,b,c){var s=t.z
return this.bV(a,b,c,s,s,s)},
bR(a){return a},
b1(a){var s=t.z
return this.bR(a,s,s,s)}}
A.dr.prototype={
$0(){return this.a.bW(this.b)},
$S:0}
A.e.prototype={
gB(a){return new A.au(a,this.gl(a),A.aG(a).i("au<e.E>"))},
E(a,b){return this.k(a,b)},
X(a,b){return new A.M(a,A.aG(a).i("@<e.E>").A(b).i("M<1,2>"))},
bE(a,b,c,d){var s
A.b3(b,c,this.gl(a))
for(s=b;s<c;++s)this.q(a,s,d)},
h(a){return A.eW(a,"[","]")},
$ic:1,
$if:1}
A.P.prototype={
C(a,b){var s,r,q,p
for(s=this.gO(),s=s.gB(s),r=A.E(this).i("P.V");s.m();){q=s.gp()
p=this.k(0,q)
b.$2(q,p==null?r.a(p):p)}},
gl(a){var s=this.gO()
return s.gl(s)},
h(a){return A.ek(this)},
$ix:1}
A.cK.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.i(a)
s=r.a+=s
r.a=s+": "
s=A.i(b)
r.a+=s},
$S:18}
A.cl.prototype={
q(a,b,c){throw A.a(A.T("Cannot modify unmodifiable map"))}}
A.aW.prototype={
k(a,b){return this.a.k(0,b)},
q(a,b,c){this.a.q(0,b,c)},
C(a,b){this.a.C(0,b)},
gl(a){var s=this.a
return s.gl(s)},
h(a){return this.a.h(0)},
$ix:1}
A.a7.prototype={}
A.bm.prototype={}
A.cc.prototype={
k(a,b){var s,r=this.b
if(r==null)return this.c.k(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.bs(b):s}},
gl(a){return this.b==null?this.c.a:this.M().length},
gO(){if(this.b==null){var s=this.c
return new A.O(s,A.E(s).i("O<1>"))}return new A.cd(this)},
q(a,b,c){var s,r,q=this
if(q.b==null)q.c.q(0,b,c)
else if(q.H(b)){s=q.b
s[b]=c
r=q.a
if(r==null?s!=null:r!==s)r[b]=null}else q.by().q(0,b,c)},
H(a){if(this.b==null)return this.c.H(a)
return Object.prototype.hasOwnProperty.call(this.a,a)},
C(a,b){var s,r,q,p,o=this
if(o.b==null)return o.c.C(0,b)
s=o.M()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.dM(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.a(A.as(o))}},
M(){var s=this.c
if(s==null)s=this.c=A.h(Object.keys(this.a),t.s)
return s},
by(){var s,r,q,p,o,n=this
if(n.b==null)return n.c
s=A.ej(t.N,t.z)
r=n.M()
for(q=0;p=r.length,q<p;++q){o=r[q]
s.q(0,o,n.k(0,o))}if(p===0)r.push("")
else B.b.Y(r)
n.a=n.b=null
return n.c=s},
bs(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.dM(this.a[a])
return this.b[a]=s}}
A.cd.prototype={
gl(a){return this.a.gl(0)},
E(a,b){var s=this.a
return s.b==null?s.gO().E(0,b):s.M()[b]},
gB(a){var s=this.a
if(s.b==null){s=s.gO()
s=s.gB(s)}else{s=s.M()
s=new J.ar(s,s.length,A.am(s).i("ar<1>"))}return s}}
A.dG.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:true})
return s}catch(r){}return null},
$S:7}
A.dF.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:false})
return s}catch(r){}return null},
$S:7}
A.cq.prototype={
bP(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a="Invalid base64 encoding length "
a2=A.b3(a1,a2,a0.length)
s=$.hk()
for(r=a1,q=r,p=null,o=-1,n=-1,m=0;r<a2;r=l){l=r+1
k=a0.charCodeAt(r)
if(k===37){j=l+2
if(j<=a2){i=A.e0(a0.charCodeAt(l))
h=A.e0(a0.charCodeAt(l+1))
g=i*16+h-(h&256)
if(g===37)g=-1
l=j}else g=-1}else g=k
if(0<=g&&g<=127){f=s[g]
if(f>=0){g="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charCodeAt(f)
if(g===k)continue
k=g}else{if(f===-1){if(o<0){e=p==null?null:p.a.length
if(e==null)e=0
o=e+(r-q)
n=r}++m
if(k===61)continue}k=g}if(f!==-2){if(p==null){p=new A.y("")
e=p}else e=p
e.a+=B.a.j(a0,q,r)
d=A.Q(k)
e.a+=d
q=l
continue}}throw A.a(A.z("Invalid base64 data",a0,r))}if(p!=null){e=B.a.j(a0,q,a2)
e=p.a+=e
d=e.length
if(o>=0)A.eO(a0,n,a2,o,m,d)
else{c=B.c.a1(d-1,4)+1
if(c===1)throw A.a(A.z(a,a0,a2))
for(;c<4;){e+="="
p.a=e;++c}}e=p.a
return B.a.J(a0,a1,a2,e.charCodeAt(0)==0?e:e)}b=a2-a1
if(o>=0)A.eO(a0,n,a2,o,m,b)
else{c=B.c.a1(b,4)
if(c===1)throw A.a(A.z(a,a0,a2))
if(c>1)a0=B.a.J(a0,a2,a2,c===2?"==":"=")}return a0}}
A.cr.prototype={}
A.bC.prototype={}
A.bE.prototype={}
A.cv.prototype={}
A.cy.prototype={
h(a){return"unknown"}}
A.cx.prototype={
I(a){var s=this.bl(a,0,a.length)
return s==null?a:s},
bl(a,b,c){var s,r,q,p
for(s=b,r=null;s<c;++s){switch(a[s]){case"&":q="&amp;"
break
case'"':q="&quot;"
break
case"'":q="&#39;"
break
case"<":q="&lt;"
break
case">":q="&gt;"
break
case"/":q="&#47;"
break
default:q=null}if(q!=null){if(r==null)r=new A.y("")
if(s>b)r.a+=B.a.j(a,b,s)
r.a+=q
b=s+1}}if(r==null)return null
if(c>b){p=B.a.j(a,b,c)
r.a+=p}p=r.a
return p.charCodeAt(0)==0?p:p}}
A.cH.prototype={
bA(a,b){var s=A.jo(a,this.gbC().a)
return s},
gbC(){return B.L}}
A.cI.prototype={}
A.d0.prototype={}
A.d2.prototype={
I(a){var s,r,q,p=A.b3(0,null,a.length)
if(p===0)return new Uint8Array(0)
s=p*3
r=new Uint8Array(s)
q=new A.dH(r)
if(q.bp(a,0,p)!==p)q.ac()
return new Uint8Array(r.subarray(0,A.iX(0,q.b,s)))}}
A.dH.prototype={
ac(){var s=this,r=s.c,q=s.b,p=s.b=q+1
r[q]=239
q=s.b=p+1
r[p]=191
s.b=q+1
r[q]=189},
bz(a,b){var s,r,q,p,o=this
if((b&64512)===56320){s=65536+((a&1023)<<10)|b&1023
r=o.c
q=o.b
p=o.b=q+1
r[q]=s>>>18|240
q=o.b=p+1
r[p]=s>>>12&63|128
p=o.b=q+1
r[q]=s>>>6&63|128
o.b=p+1
r[p]=s&63|128
return!0}else{o.ac()
return!1}},
bp(a,b,c){var s,r,q,p,o,n,m,l=this
if(b!==c&&(a.charCodeAt(c-1)&64512)===55296)--c
for(s=l.c,r=s.length,q=b;q<c;++q){p=a.charCodeAt(q)
if(p<=127){o=l.b
if(o>=r)break
l.b=o+1
s[o]=p}else{o=p&64512
if(o===55296){if(l.b+4>r)break
n=q+1
if(l.bz(p,a.charCodeAt(n)))q=n}else if(o===56320){if(l.b+3>r)break
l.ac()}else if(p<=2047){o=l.b
m=o+1
if(m>=r)break
l.b=m
s[o]=p>>>6|192
l.b=m+1
s[m]=p&63|128}else{o=l.b
if(o+2>=r)break
m=l.b=o+1
s[o]=p>>>12|224
o=l.b=m+1
s[m]=p>>>6&63|128
l.b=o+1
s[o]=p&63|128}}}return q}}
A.d1.prototype={
I(a){return new A.dE(this.a).bm(a,0,null,!0)}}
A.dE.prototype={
bm(a,b,c,d){var s,r,q,p,o,n,m=this,l=A.b3(b,c,J.aI(a))
if(b===l)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.iQ(a,b,l)
l-=b
q=b
b=0}if(l-b>=15){p=m.a
o=A.iP(p,r,b,l)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.a5(r,b,l,!0)
p=m.b
if((p&1)!==0){n=A.iR(p)
m.b=0
throw A.a(A.z(n,a,q+m.c))}return o},
a5(a,b,c,d){var s,r,q=this
if(c-b>1000){s=B.c.bw(b+c,2)
r=q.a5(a,b,s,!1)
if((q.b&1)!==0)return r
return r+q.a5(a,s,c,d)}return q.bB(a,b,c,d)},
bB(a,b,c,d){var s,r,q,p,o,n,m,l=this,k=65533,j=l.b,i=l.c,h=new A.y(""),g=b+1,f=a[b]
$label0$0:for(s=l.a;!0;){for(;!0;g=p){r="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE".charCodeAt(f)&31
i=j<=32?f&61694>>>r:(f&63|i<<6)>>>0
j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA".charCodeAt(j+r)
if(j===0){q=A.Q(i)
h.a+=q
if(g===c)break $label0$0
break}else if((j&1)!==0){if(s)switch(j){case 69:case 67:q=A.Q(k)
h.a+=q
break
case 65:q=A.Q(k)
h.a+=q;--g
break
default:q=A.Q(k)
q=h.a+=q
h.a=q+A.Q(k)
break}else{l.b=j
l.c=g-1
return""}j=0}if(g===c)break $label0$0
p=g+1
f=a[g]}p=g+1
f=a[g]
if(f<128){while(!0){if(!(p<c)){o=c
break}n=p+1
f=a[p]
if(f>=128){o=n-1
p=n
break}p=n}if(o-g<20)for(m=g;m<o;++m){q=A.Q(a[m])
h.a+=q}else{q=A.fc(a,g,o)
h.a+=q}if(o===c)break $label0$0
g=p}else g=p}if(d&&j>32)if(s){s=A.Q(k)
h.a+=s}else{l.b=77
l.c=c
return""}l.b=j
l.c=i
s=h.a
return s.charCodeAt(0)==0?s:s}}
A.cM.prototype={
$2(a,b){var s=this.b,r=this.a,q=s.a+=r.a
q+=a.a
s.a=q
s.a=q+": "
q=A.at(b)
s.a+=q
r.a=", "},
$S:19}
A.dD.prototype={
$2(a,b){var s,r
if(typeof b=="string")this.a.set(a,b)
else if(b==null)this.a.set(a,"")
else for(s=J.L(b),r=this.a;s.m();){b=s.gp()
if(typeof b=="string")r.append(a,b)
else if(b==null)r.append(a,"")
else A.iT(b)}},
$S:2}
A.d8.prototype={
h(a){return this.aA()}}
A.k.prototype={
gR(){return A.i2(this)}}
A.bx.prototype={
h(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.at(s)
return"Assertion failed"}}
A.R.prototype={}
A.G.prototype={
ga7(){return"Invalid argument"+(!this.a?"(s)":"")},
ga6(){return""},
h(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+p,n=s.ga7()+q+o
if(!s.a)return n
return n+s.ga6()+": "+A.at(s.gal())},
gal(){return this.b}}
A.b2.prototype={
gal(){return this.b},
ga7(){return"RangeError"},
ga6(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.i(q):""
else if(q==null)s=": Not greater than or equal to "+A.i(r)
else if(q>r)s=": Not in inclusive range "+A.i(r)+".."+A.i(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.i(r)
return s}}
A.bF.prototype={
gal(){return this.b},
ga7(){return"RangeError"},
ga6(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gl(a){return this.f}}
A.bV.prototype={
h(a){var s,r,q,p,o,n,m,l,k=this,j={},i=new A.y("")
j.a=""
s=k.c
for(r=s.length,q=0,p="",o="";q<r;++q,o=", "){n=s[q]
i.a=p+o
p=A.at(n)
p=i.a+=p
j.a=", "}k.d.C(0,new A.cM(j,i))
m=A.at(k.a)
l=i.h(0)
return"NoSuchMethodError: method not found: '"+k.b.a+"'\nReceiver: "+m+"\nArguments: ["+l+"]"}}
A.c2.prototype={
h(a){return"Unsupported operation: "+this.a}}
A.c_.prototype={
h(a){return"UnimplementedError: "+this.a}}
A.b5.prototype={
h(a){return"Bad state: "+this.a}}
A.bD.prototype={
h(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.at(s)+"."}}
A.bW.prototype={
h(a){return"Out of Memory"},
gR(){return null},
$ik:1}
A.b4.prototype={
h(a){return"Stack Overflow"},
gR(){return null},
$ik:1}
A.d9.prototype={
h(a){return"Exception: "+this.a}}
A.cw.prototype={
h(a){var s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=""!==h?"FormatException: "+h:"FormatException",f=this.c,e=this.b
if(typeof e=="string"){if(f!=null)s=f<0||f>e.length
else s=!1
if(s)f=null
if(f==null){if(e.length>78)e=B.a.j(e,0,75)+"..."
return g+"\n"+e}for(r=1,q=0,p=!1,o=0;o<f;++o){n=e.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}g=r>1?g+(" (at line "+r+", character "+(f-q+1)+")\n"):g+(" (at character "+(f+1)+")\n")
m=e.length
for(o=f;o<m;++o){n=e.charCodeAt(o)
if(n===10||n===13){m=o
break}}if(m-q>78)if(f-q<75){l=q+75
k=q
j=""
i="..."}else{if(m-f<75){k=m-75
l=m
i=""}else{k=f-36
l=f+36
i="..."}j="..."}else{l=m
k=q
j=""
i=""}return g+j+B.a.j(e,k,l)+i+"\n"+B.a.b9(" ",f-k+j.length)+"^\n"}else return f!=null?g+(" (at offset "+A.i(f)+")"):g}}
A.n.prototype={
X(a,b){return A.hA(this,A.E(this).i("n.E"),b)},
gl(a){var s,r=this.gB(this)
for(s=0;r.m();)++s
return s},
E(a,b){var s,r
A.f5(b,"index")
s=this.gB(this)
for(r=b;s.m();){if(r===0)return s.gp();--r}throw A.a(A.eU(b,b-r,this,"index"))},
h(a){return A.hP(this,"(",")")}}
A.u.prototype={
gn(a){return A.l.prototype.gn.call(this,0)},
h(a){return"null"}}
A.l.prototype={$il:1,
F(a,b){return this===b},
gn(a){return A.bY(this)},
h(a){return"Instance of '"+A.cQ(this)+"'"},
b_(a,b){throw A.a(A.f1(this,b))},
gt(a){return A.jL(this)},
toString(){return this.h(this)}}
A.cj.prototype={
h(a){return""},
$ia4:1}
A.y.prototype={
gl(a){return this.a.length},
h(a){var s=this.a
return s.charCodeAt(0)==0?s:s}}
A.d_.prototype={
$2(a,b){var s,r,q,p=B.a.aU(b,"=")
if(p===-1){if(b!=="")a.q(0,A.ew(b,0,b.length,this.a,!0),"")}else if(p!==0){s=B.a.j(b,0,p)
r=B.a.K(b,p+1)
q=this.a
a.q(0,A.ew(s,0,s.length,q,!0),A.ew(r,0,r.length,q,!0))}return a},
$S:20}
A.cX.prototype={
$2(a,b){throw A.a(A.z("Illegal IPv4 address, "+a,this.a,b))},
$S:21}
A.cY.prototype={
$2(a,b){throw A.a(A.z("Illegal IPv6 address, "+a,this.a,b))},
$S:22}
A.cZ.prototype={
$2(a,b){var s
if(b-a>4)this.a.$2("an IPv6 part can only contain a maximum of 4 hex digits",a)
s=A.e8(B.a.j(this.b,a,b),16)
if(s<0||s>65535)this.a.$2("each part must be in the range of `0x0..0xFFFF`",a)
return s},
$S:23}
A.bn.prototype={
gW(){var s,r,q,p,o=this,n=o.w
if(n===$){s=o.a
r=s.length!==0?""+s+":":""
q=o.c
p=q==null
if(!p||s==="file"){s=r+"//"
r=o.b
if(r.length!==0)s=s+r+"@"
if(!p)s+=q
r=o.d
if(r!=null)s=s+":"+A.i(r)}else s=r
s+=o.e
r=o.f
if(r!=null)s=s+"?"+r
r=o.r
if(r!=null)s=s+"#"+r
n!==$&&A.bv()
n=o.w=s.charCodeAt(0)==0?s:s}return n},
gn(a){var s,r=this,q=r.y
if(q===$){s=B.a.gn(r.gW())
r.y!==$&&A.bv()
r.y=s
q=s}return q},
gao(){var s,r=this,q=r.z
if(q===$){s=r.f
s=A.fh(s==null?"":s)
r.z!==$&&A.bv()
q=r.z=new A.a7(s,t.h)}return q},
gb4(){return this.b},
gaj(){var s=this.c
if(s==null)return""
if(B.a.u(s,"["))return B.a.j(s,1,s.length-1)
return s},
ga0(){var s=this.d
return s==null?A.fu(this.a):s},
gan(){var s=this.f
return s==null?"":s},
gaO(){var s=this.r
return s==null?"":s},
ap(a){var s,r,q,p,o=this,n=o.a,m=n==="file",l=o.b,k=o.d,j=o.c
if(!(j!=null))j=l.length!==0||k!=null||m?"":null
s=o.e
if(!m)r=j!=null&&s.length!==0
else r=!0
if(r&&!B.a.u(s,"/"))s="/"+s
q=s
p=A.eu(null,0,0,a)
return A.es(n,l,j,k,q,p,o.r)},
gaX(){if(this.a!==""){var s=this.r
s=(s==null?"":s)===""}else s=!1
return s},
gaQ(){return this.c!=null},
gaT(){return this.f!=null},
gaR(){return this.r!=null},
h(a){return this.gW()},
F(a,b){var s,r,q=this
if(b==null)return!1
if(q===b)return!0
if(t.R.b(b))if(q.a===b.ga2())if(q.c!=null===b.gaQ())if(q.b===b.gb4())if(q.gaj()===b.gaj())if(q.ga0()===b.ga0())if(q.e===b.gb0()){s=q.f
r=s==null
if(!r===b.gaT()){if(r)s=""
if(s===b.gan()){s=q.r
r=s==null
if(!r===b.gaR()){if(r)s=""
s=s===b.gaO()}else s=!1}else s=!1}else s=!1}else s=!1
else s=!1
else s=!1
else s=!1
else s=!1
else s=!1
else s=!1
return s},
$ic3:1,
ga2(){return this.a},
gb0(){return this.e}}
A.dC.prototype={
$2(a,b){var s=this.b,r=this.a
s.a+=r.a
r.a="&"
r=A.fA(B.h,a,B.e,!0)
r=s.a+=r
if(b!=null&&b.length!==0){s.a=r+"="
r=A.fA(B.h,b,B.e,!0)
s.a+=r}},
$S:24}
A.dB.prototype={
$2(a,b){var s,r
if(b==null||typeof b=="string")this.a.$2(a,b)
else for(s=J.L(b),r=this.a;s.m();)r.$2(a,s.gp())},
$S:2}
A.cW.prototype={
gb3(){var s,r,q,p,o=this,n=null,m=o.c
if(m==null){m=o.a
s=o.b[0]+1
r=B.a.Z(m,"?",s)
q=m.length
if(r>=0){p=A.bo(m,r+1,q,B.f,!1,!1)
q=r}else p=n
m=o.c=new A.c9("data","",n,n,A.bo(m,s,q,B.p,!1,!1),p,n)}return m},
h(a){var s=this.a
return this.b[0]===-1?"data:"+s:s}}
A.dP.prototype={
$2(a,b){var s=this.a[a]
B.ab.bE(s,0,96,b)
return s},
$S:25}
A.dQ.prototype={
$3(a,b,c){var s,r
for(s=b.length,r=0;r<s;++r)a[b.charCodeAt(r)^96]=c},
$S:8}
A.dR.prototype={
$3(a,b,c){var s,r
for(s=b.charCodeAt(0),r=b.charCodeAt(1);s<=r;++s)a[(s^96)>>>0]=c},
$S:8}
A.ch.prototype={
gaQ(){return this.c>0},
gaS(){return this.c>0&&this.d+1<this.e},
gaT(){return this.f<this.r},
gaR(){return this.r<this.a.length},
gaX(){return this.b>0&&this.r>=this.a.length},
ga2(){var s=this.w
return s==null?this.w=this.bk():s},
bk(){var s,r=this,q=r.b
if(q<=0)return""
s=q===4
if(s&&B.a.u(r.a,"http"))return"http"
if(q===5&&B.a.u(r.a,"https"))return"https"
if(s&&B.a.u(r.a,"file"))return"file"
if(q===7&&B.a.u(r.a,"package"))return"package"
return B.a.j(r.a,0,q)},
gb4(){var s=this.c,r=this.b+3
return s>r?B.a.j(this.a,r,s-1):""},
gaj(){var s=this.c
return s>0?B.a.j(this.a,s,this.d):""},
ga0(){var s,r=this
if(r.gaS())return A.e8(B.a.j(r.a,r.d+1,r.e),null)
s=r.b
if(s===4&&B.a.u(r.a,"http"))return 80
if(s===5&&B.a.u(r.a,"https"))return 443
return 0},
gb0(){return B.a.j(this.a,this.e,this.f)},
gan(){var s=this.f,r=this.r
return s<r?B.a.j(this.a,s+1,r):""},
gaO(){var s=this.r,r=this.a
return s<r.length?B.a.K(r,s+1):""},
gao(){if(this.f>=this.r)return B.aa
return new A.a7(A.fh(this.gan()),t.h)},
ap(a){var s,r,q,p,o,n=this,m=null,l=n.ga2(),k=l==="file",j=n.c,i=j>0?B.a.j(n.a,n.b+3,j):"",h=n.gaS()?n.ga0():m
j=n.c
if(j>0)s=B.a.j(n.a,j,n.d)
else s=i.length!==0||h!=null||k?"":m
j=n.a
r=B.a.j(j,n.e,n.f)
if(!k)q=s!=null&&r.length!==0
else q=!0
if(q&&!B.a.u(r,"/"))r="/"+r
p=A.eu(m,0,0,a)
q=n.r
o=q<j.length?B.a.K(j,q+1):m
return A.es(l,i,s,h,r,p,o)},
gn(a){var s=this.x
return s==null?this.x=B.a.gn(this.a):s},
F(a,b){if(b==null)return!1
if(this===b)return!0
return t.R.b(b)&&this.a===b.h(0)},
h(a){return this.a},
$ic3:1}
A.c9.prototype={}
A.ec.prototype={
$1(a){return this.a.ae(a)},
$S:3}
A.ed.prototype={
$1(a){if(a==null)return this.a.aM(new A.cN(a===undefined))
return this.a.aM(a)},
$S:3}
A.cN.prototype={
h(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."}}
A.m.prototype={
aA(){return"Kind."+this.b},
h(a){var s
switch(this.a){case 0:s="accessor"
break
case 1:s="constant"
break
case 2:s="constructor"
break
case 3:s="class"
break
case 4:s="dynamic"
break
case 5:s="enum"
break
case 6:s="extension"
break
case 7:s="extension type"
break
case 8:s="function"
break
case 9:s="library"
break
case 10:s="method"
break
case 11:s="mixin"
break
case 12:s="Never"
break
case 13:s="package"
break
case 14:s="parameter"
break
case 15:s="prefix"
break
case 16:s="property"
break
case 17:s="SDK"
break
case 18:s="topic"
break
case 19:s="top-level constant"
break
case 20:s="top-level property"
break
case 21:s="typedef"
break
case 22:s="type parameter"
break
default:s=null}return s}}
A.A.prototype={
aA(){return"_MatchPosition."+this.b}}
A.cz.prototype={
aN(a){var s,r,q,p,o,n,m,l,k,j,i
if(a.length===0)return A.h([],t.M)
s=a.toLowerCase()
r=A.h([],t.r)
for(q=this.a,p=q.length,o=s.length>1,n="dart:"+s,m=0;m<q.length;q.length===p||(0,A.co)(q),++m){l=q[m]
k=new A.cC(r,l)
j=l.a.toLowerCase()
i=l.b.toLowerCase()
if(j===s||i===s||j===n)k.$1(B.aq)
else if(o)if(B.a.u(j,s)||B.a.u(i,s))k.$1(B.ar)
else if(B.a.ag(j,s)||B.a.ag(i,s))k.$1(B.as)}B.b.bc(r,new A.cA())
q=t.V
return A.bL(new A.ak(r,new A.cB(),q),!0,q.i("J.E"))}}
A.cC.prototype={
$1(a){this.a.push(new A.cg(this.b,a))},
$S:26}
A.cA.prototype={
$2(a,b){var s,r,q=a.b.a-b.b.a
if(q!==0)return q
s=a.a
r=b.a
q=s.c-r.c
if(q!==0)return q
q=s.gaD()-r.gaD()
if(q!==0)return q
q=s.f-r.f
if(q!==0)return q
return s.a.length-r.a.length},
$S:27}
A.cB.prototype={
$1(a){return a.a},
$S:28}
A.w.prototype={
gaD(){switch(this.d.a){case 3:var s=0
break
case 5:s=0
break
case 6:s=0
break
case 7:s=0
break
case 11:s=0
break
case 19:s=0
break
case 20:s=0
break
case 21:s=0
break
case 0:s=1
break
case 1:s=1
break
case 2:s=1
break
case 8:s=1
break
case 10:s=1
break
case 16:s=1
break
case 9:s=2
break
case 13:s=2
break
case 18:s=2
break
case 4:s=3
break
case 12:s=3
break
case 14:s=3
break
case 15:s=3
break
case 17:s=3
break
case 22:s=3
break
default:s=null}return s}}
A.cu.prototype={}
A.dT.prototype={
$0(){var s,r=self.document.body
if(r==null)return""
if(J.F(r.getAttribute("data-using-base-href"),"false")){s=r.getAttribute("data-base-href")
return s==null?"":s}else return""},
$S:29}
A.e6.prototype={
$0(){A.jZ("Could not activate search functionality.")
var s=this.a
if(s!=null)s.placeholder="Failed to initialize search"
s=this.b
if(s!=null)s.placeholder="Failed to initialize search"
s=this.c
if(s!=null)s.placeholder="Failed to initialize search"},
$S:0}
A.e5.prototype={
$1(a){return this.b8(a)},
b8(a){var s=0,r=A.fS(t.P),q,p=this,o,n,m,l,k,j,i,h,g
var $async$$1=A.fZ(function(b,c){if(b===1)return A.fI(c,r)
while(true)switch(s){case 0:if(!J.F(a.status,200)){p.a.$0()
s=1
break}i=J
h=t.j
g=B.E
s=3
return A.fH(A.eb(a.text(),t.N),$async$$1)
case 3:o=i.ht(h.a(g.bA(c,null)),t.a)
n=o.$ti.i("ak<e.E,w>")
m=new A.cz(A.bL(new A.ak(o,A.k1(),n),!0,n.i("J.E")))
n=self
l=A.c4(J.aq(n.window.location)).gao().k(0,"search")
if(l!=null){k=m.aN(l)
if(k.length!==0){j=B.b.gbF(k).e
if(j!=null){n.window.location.assign($.bw()+j)
s=1
break}}}n=p.b
if(n!=null)A.eo(m).ak(n)
n=p.c
if(n!=null)A.eo(m).ak(n)
n=p.d
if(n!=null)A.eo(m).ak(n)
case 1:return A.fJ(q,r)}})
return A.fK($async$$1,r)},
$S:9}
A.ds.prototype={
gG(){var s,r=this,q=r.c
if(q===$){s=self.document.createElement("div")
s.setAttribute("role","listbox")
s.setAttribute("aria-expanded","false")
s.style.display="none"
s.classList.add("tt-menu")
s.appendChild(r.gaZ())
s.appendChild(r.gP())
r.c!==$&&A.bv()
r.c=s
q=s}return q},
gaZ(){var s,r=this.d
if(r===$){s=self.document.createElement("div")
s.classList.add("enter-search-message")
this.d!==$&&A.bv()
this.d=s
r=s}return r},
gP(){var s,r=this.e
if(r===$){s=self.document.createElement("div")
s.classList.add("tt-search-results")
this.e!==$&&A.bv()
this.e=s
r=s}return r},
ak(a){var s,r,q,p=this
a.disabled=!1
a.setAttribute("placeholder","Search API Docs")
s=self
s.document.addEventListener("keydown",t.g.a(A.ab(new A.dt(a))))
r=s.document.createElement("div")
r.classList.add("tt-wrapper")
a.replaceWith(r)
a.setAttribute("autocomplete","off")
a.setAttribute("spellcheck","false")
a.classList.add("tt-input")
r.appendChild(a)
r.appendChild(p.gG())
p.ba(a)
if(J.hv(s.window.location.href,"search.html")){q=p.b.gao().k(0,"q")
if(q==null)return
q=B.k.I(q)
$.eD=$.dX
p.bK(q,!0)
p.bb(q)
p.ai()
$.eD=10}},
bb(a){var s,r,q,p,o,n=self,m=n.document.getElementById("dartdoc-main-content")
if(m==null)return
m.textContent=""
s=n.document.createElement("section")
s.classList.add("search-summary")
m.appendChild(s)
s=n.document.createElement("h2")
s.innerHTML="Search Results"
m.appendChild(s)
s=n.document.createElement("div")
s.classList.add("search-summary")
s.innerHTML=""+$.dX+' results for "'+a+'"'
m.appendChild(s)
if($.bq.a!==0)for(n=$.bq.gb5(),s=A.E(n),s=s.i("@<1>").A(s.y[1]),n=new A.av(J.L(n.a),n.b,s.i("av<1,2>")),s=s.y[1];n.m();){r=n.a
if(r==null)r=s.a(r)
m.appendChild(r)}else{q=n.document.createElement("div")
q.classList.add("search-summary")
q.innerHTML='There was not a match for "'+a+'". Want to try searching from additional Dart-related sites? '
p=A.c4("https://dart.dev/search?cx=011220921317074318178%3A_yy-tmb5t_i&ie=UTF-8&hl=en&q=").ap(A.f_(["q",a],t.N,t.z))
o=n.document.createElement("a")
o.setAttribute("href",p.gW())
o.textContent="Search on dart.dev."
q.appendChild(o)
m.appendChild(q)}},
ai(){var s=this.gG()
s.style.display="none"
s.setAttribute("aria-expanded","false")
return s},
b2(a,b,c){var s,r,q,p,o=this
o.x=A.h([],t.M)
s=o.w
B.b.Y(s)
$.bq.Y(0)
o.gP().textContent=""
r=b.length
if(r===0){o.ai()
return}for(q=0;q<b.length;b.length===r||(0,A.co)(b),++q)s.push(A.iZ(a,b[q]))
for(r=J.L(c?$.bq.gb5():s);r.m();){p=r.gp()
o.gP().appendChild(p)}o.x=b
o.y=-1
if(o.gP().hasChildNodes()){r=o.gG()
r.style.display="block"
r.setAttribute("aria-expanded","true")}r=$.dX
r=r>10?'Press "Enter" key to see all '+r+" results":""
o.gaZ().textContent=r},
bY(a,b){return this.b2(a,b,!1)},
ah(a,b,c){var s,r,q,p=this
if(p.r===a&&!b)return
if(a.length===0){p.bY("",A.h([],t.M))
return}s=p.a.aN(a)
r=s.length
$.dX=r
q=$.eD
if(r>q)s=B.b.bd(s,0,q)
p.r=a
p.b2(a,s,c)},
bK(a,b){return this.ah(a,!1,b)},
aP(a){return this.ah(a,!1,!1)},
bJ(a,b){return this.ah(a,b,!1)},
aK(a){var s,r=this
r.y=-1
s=r.f
if(s!=null){a.value=s
r.f=null}r.ai()},
ba(a){var s=this,r=t.g
a.addEventListener("focus",r.a(A.ab(new A.du(s,a))))
a.addEventListener("blur",r.a(A.ab(new A.dv(s,a))))
a.addEventListener("input",r.a(A.ab(new A.dw(s,a))))
a.addEventListener("keydown",r.a(A.ab(new A.dx(s,a))))}}
A.dt.prototype={
$1(a){if(J.F(a.key,"/")&&!t.m.b(self.document.activeElement)){a.preventDefault()
this.a.focus()}},
$S:1}
A.du.prototype={
$1(a){this.a.bJ(this.b.value,!0)},
$S:1}
A.dv.prototype={
$1(a){this.a.aK(this.b)},
$S:1}
A.dw.prototype={
$1(a){this.a.aP(this.b.value)},
$S:1}
A.dx.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this
if(!J.F(a.type,"keydown"))return
if(J.F(a.code,"Enter")){a.preventDefault()
s=e.a
r=s.y
if(r!==-1){q=s.w[r].getAttribute("data-href")
if(q!=null)self.window.location.assign($.bw()+q)
return}else{p=B.k.I(s.r)
o=A.c4($.bw()+"search.html").ap(A.f_(["q",p],t.N,t.z))
self.window.location.assign(o.gW())
return}}s=e.a
r=s.w
n=r.length-1
m=s.y
if(J.F(a.code,"ArrowUp")){l=s.y
if(l===-1)s.y=n
else s.y=l-1}else if(J.F(a.code,"ArrowDown")){l=s.y
if(l===n)s.y=-1
else s.y=l+1}else if(J.F(a.code,"Escape"))s.aK(e.b)
else{if(s.f!=null){s.f=null
s.aP(e.b.value)}return}l=m!==-1
if(l)r[m].classList.remove("tt-cursor")
k=s.y
if(k!==-1){j=r[k]
j.classList.add("tt-cursor")
r=s.y
if(r===0)s.gG().scrollTop=0
else if(r===n)s.gG().scrollTop=s.gG().scrollHeight
else{i=j.offsetTop
h=s.gG().offsetHeight
if(i<h||h<i+j.offsetHeight)j.scrollIntoView()}if(s.f==null)s.f=e.b.value
e.b.value=s.x[s.y].a}else{g=s.f
if(g!=null){r=l
f=g}else{f=null
r=!1}if(r){e.b.value=f
s.f=null}}a.preventDefault()},
$S:1}
A.dN.prototype={
$1(a){a.preventDefault()},
$S:1}
A.dO.prototype={
$1(a){var s=this.a.e
if(s!=null){self.window.location.assign($.bw()+s)
a.preventDefault()}},
$S:1}
A.dS.prototype={
$1(a){return"<strong class='tt-highlight'>"+A.i(a.k(0,0))+"</strong>"},
$S:30}
A.dU.prototype={
$1(a){var s=this.a
if(s!=null)s.classList.toggle("active")
s=this.b
if(s!=null)s.classList.toggle("active")},
$S:1}
A.dV.prototype={
$1(a){return this.b7(a)},
b7(a){var s=0,r=A.fS(t.P),q,p=this,o,n,m
var $async$$1=A.fZ(function(b,c){if(b===1)return A.fI(c,r)
while(true)switch(s){case 0:if(!J.F(a.status,200)){o=self.document.createElement("a")
o.href="https://dart.dev/tools/dart-doc#troubleshoot"
o.text="Failed to load sidebar. Visit dart.dev for help troubleshooting."
p.a.appendChild(o)
s=1
break}s=3
return A.fH(A.eb(a.text(),t.N),$async$$1)
case 3:n=c
m=self.document.createElement("div")
m.innerHTML=n
A.fY(p.b,m)
p.a.appendChild(m)
case 1:return A.fJ(q,r)}})
return A.fK($async$$1,r)},
$S:9}
A.e7.prototype={
$0(){var s=this.a,r=this.b
if(s.checked){r.setAttribute("class","dark-theme")
s.setAttribute("value","dark-theme")
self.window.localStorage.setItem("colorTheme","true")}else{r.setAttribute("class","light-theme")
s.setAttribute("value","light-theme")
self.window.localStorage.setItem("colorTheme","false")}},
$S:0}
A.e4.prototype={
$1(a){this.a.$0()},
$S:1};(function aliases(){var s=J.a2.prototype
s.be=s.h})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._static_1,q=hunkHelpers._static_0
s(J,"ja","hT",31)
r(A,"jA","ic",4)
r(A,"jB","id",4)
r(A,"jC","ie",4)
q(A,"h0","ju",0)
r(A,"k1","hL",32)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.l,null)
q(A.l,[A.eh,J.bG,J.ar,A.n,A.bA,A.k,A.e,A.cR,A.au,A.av,A.aO,A.c1,A.a5,A.bf,A.aW,A.aK,A.cD,A.ag,A.cU,A.cO,A.aN,A.bg,A.dp,A.P,A.cJ,A.bK,A.cE,A.ce,A.d3,A.I,A.cb,A.dA,A.dy,A.c5,A.bz,A.c7,A.az,A.v,A.c6,A.ci,A.dJ,A.cl,A.bC,A.bE,A.cy,A.dH,A.dE,A.d8,A.bW,A.b4,A.d9,A.cw,A.u,A.cj,A.y,A.bn,A.cW,A.ch,A.cN,A.cz,A.w,A.cu,A.ds])
q(J.bG,[J.bH,J.aQ,J.aT,J.aS,J.aU,J.aR,J.ai])
q(J.aT,[J.a2,J.o,A.bM,A.aZ])
q(J.a2,[J.bX,J.ax,J.a1])
r(J.cF,J.o)
q(J.aR,[J.aP,J.bI])
q(A.n,[A.a8,A.c,A.aj])
q(A.a8,[A.af,A.bp])
r(A.b9,A.af)
r(A.b8,A.bp)
r(A.M,A.b8)
q(A.k,[A.aV,A.R,A.bJ,A.c0,A.c8,A.bZ,A.ca,A.bx,A.G,A.bV,A.c2,A.c_,A.b5,A.bD])
r(A.ay,A.e)
r(A.bB,A.ay)
q(A.c,[A.J,A.O])
r(A.aM,A.aj)
q(A.J,[A.ak,A.cd])
r(A.cf,A.bf)
r(A.cg,A.cf)
r(A.bm,A.aW)
r(A.a7,A.bm)
r(A.aL,A.a7)
r(A.ah,A.aK)
q(A.ag,[A.ct,A.cs,A.cT,A.cG,A.e1,A.e3,A.d5,A.d4,A.dK,A.de,A.dl,A.dQ,A.dR,A.ec,A.ed,A.cC,A.cB,A.e5,A.dt,A.du,A.dv,A.dw,A.dx,A.dN,A.dO,A.dS,A.dU,A.dV,A.e4])
q(A.ct,[A.cP,A.e2,A.dL,A.dY,A.df,A.cK,A.cM,A.dD,A.d_,A.cX,A.cY,A.cZ,A.dC,A.dB,A.dP,A.cA])
r(A.b1,A.R)
q(A.cT,[A.cS,A.aJ])
q(A.P,[A.N,A.cc])
q(A.aZ,[A.bN,A.aw])
q(A.aw,[A.bb,A.bd])
r(A.bc,A.bb)
r(A.aX,A.bc)
r(A.be,A.bd)
r(A.aY,A.be)
q(A.aX,[A.bO,A.bP])
q(A.aY,[A.bQ,A.bR,A.bS,A.bT,A.bU,A.b_,A.b0])
r(A.bh,A.ca)
q(A.cs,[A.d6,A.d7,A.dz,A.da,A.dh,A.dg,A.dd,A.dc,A.db,A.dk,A.dj,A.di,A.dW,A.dr,A.dG,A.dF,A.dT,A.e6,A.e7])
r(A.b7,A.c7)
r(A.dq,A.dJ)
q(A.bC,[A.cq,A.cv,A.cH])
q(A.bE,[A.cr,A.cx,A.cI,A.d2,A.d1])
r(A.d0,A.cv)
q(A.G,[A.b2,A.bF])
r(A.c9,A.bn)
q(A.d8,[A.m,A.A])
s(A.ay,A.c1)
s(A.bp,A.e)
s(A.bb,A.e)
s(A.bc,A.aO)
s(A.bd,A.e)
s(A.be,A.aO)
s(A.bm,A.cl)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{b:"int",t:"double",jY:"num",d:"String",jD:"bool",u:"Null",f:"List",l:"Object",x:"Map"},mangledNames:{},types:["~()","u(p)","~(d,@)","~(@)","~(~())","u(@)","u()","@()","~(al,d,b)","a0<u>(p)","@(@)","@(@,d)","@(d)","u(~())","u(@,a4)","~(b,@)","u(l,a4)","v<@>(@)","~(l?,l?)","~(b6,@)","x<d,d>(x<d,d>,d)","~(d,b)","~(d,b?)","b(b,b)","~(d,d?)","al(@,@)","~(A)","b(+item,matchPosition(w,A),+item,matchPosition(w,A))","w(+item,matchPosition(w,A))","d()","d(cL)","b(@,@)","w(x<d,@>)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;item,matchPosition":(a,b)=>c=>c instanceof A.cg&&a.b(c.a)&&b.b(c.b)}}
A.ix(v.typeUniverse,JSON.parse('{"bX":"a2","ax":"a2","a1":"a2","bH":{"j":[]},"aQ":{"u":[],"j":[]},"aT":{"p":[]},"a2":{"p":[]},"o":{"f":["1"],"c":["1"],"p":[]},"cF":{"o":["1"],"f":["1"],"c":["1"],"p":[]},"aR":{"t":[]},"aP":{"t":[],"b":[],"j":[]},"bI":{"t":[],"j":[]},"ai":{"d":[],"j":[]},"a8":{"n":["2"]},"af":{"a8":["1","2"],"n":["2"],"n.E":"2"},"b9":{"af":["1","2"],"a8":["1","2"],"c":["2"],"n":["2"],"n.E":"2"},"b8":{"e":["2"],"f":["2"],"a8":["1","2"],"c":["2"],"n":["2"]},"M":{"b8":["1","2"],"e":["2"],"f":["2"],"a8":["1","2"],"c":["2"],"n":["2"],"e.E":"2","n.E":"2"},"aV":{"k":[]},"bB":{"e":["b"],"f":["b"],"c":["b"],"e.E":"b"},"c":{"n":["1"]},"J":{"c":["1"],"n":["1"]},"aj":{"n":["2"],"n.E":"2"},"aM":{"aj":["1","2"],"c":["2"],"n":["2"],"n.E":"2"},"ak":{"J":["2"],"c":["2"],"n":["2"],"J.E":"2","n.E":"2"},"ay":{"e":["1"],"f":["1"],"c":["1"]},"a5":{"b6":[]},"aL":{"a7":["1","2"],"x":["1","2"]},"aK":{"x":["1","2"]},"ah":{"x":["1","2"]},"b1":{"R":[],"k":[]},"bJ":{"k":[]},"c0":{"k":[]},"bg":{"a4":[]},"c8":{"k":[]},"bZ":{"k":[]},"N":{"P":["1","2"],"x":["1","2"],"P.V":"2"},"O":{"c":["1"],"n":["1"],"n.E":"1"},"ce":{"el":[],"cL":[]},"bM":{"p":[],"j":[]},"aZ":{"p":[]},"bN":{"p":[],"j":[]},"aw":{"D":["1"],"p":[]},"aX":{"e":["t"],"f":["t"],"D":["t"],"c":["t"],"p":[]},"aY":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[]},"bO":{"e":["t"],"f":["t"],"D":["t"],"c":["t"],"p":[],"j":[],"e.E":"t"},"bP":{"e":["t"],"f":["t"],"D":["t"],"c":["t"],"p":[],"j":[],"e.E":"t"},"bQ":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"bR":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"bS":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"bT":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"bU":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"b_":{"e":["b"],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"b0":{"e":["b"],"al":[],"f":["b"],"D":["b"],"c":["b"],"p":[],"j":[],"e.E":"b"},"ca":{"k":[]},"bh":{"R":[],"k":[]},"v":{"a0":["1"]},"bz":{"k":[]},"b7":{"c7":["1"]},"e":{"f":["1"],"c":["1"]},"P":{"x":["1","2"]},"aW":{"x":["1","2"]},"a7":{"x":["1","2"]},"cc":{"P":["d","@"],"x":["d","@"],"P.V":"@"},"cd":{"J":["d"],"c":["d"],"n":["d"],"J.E":"d","n.E":"d"},"f":{"c":["1"]},"el":{"cL":[]},"bx":{"k":[]},"R":{"k":[]},"G":{"k":[]},"b2":{"k":[]},"bF":{"k":[]},"bV":{"k":[]},"c2":{"k":[]},"c_":{"k":[]},"b5":{"k":[]},"bD":{"k":[]},"bW":{"k":[]},"b4":{"k":[]},"cj":{"a4":[]},"bn":{"c3":[]},"ch":{"c3":[]},"c9":{"c3":[]},"hO":{"f":["b"],"c":["b"]},"al":{"f":["b"],"c":["b"]},"i9":{"f":["b"],"c":["b"]},"hM":{"f":["b"],"c":["b"]},"i7":{"f":["b"],"c":["b"]},"hN":{"f":["b"],"c":["b"]},"i8":{"f":["b"],"c":["b"]},"hJ":{"f":["t"],"c":["t"]},"hK":{"f":["t"],"c":["t"]}}'))
A.iw(v.typeUniverse,JSON.parse('{"aO":1,"c1":1,"ay":1,"bp":2,"aK":2,"bK":1,"aw":1,"ci":1,"cl":2,"aW":2,"bm":2,"bC":2,"bE":2}'))
var u={c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type"}
var t=(function rtii(){var s=A.bt
return{Z:s("aL<b6,@>"),U:s("c<@>"),Q:s("k"),Y:s("k9"),M:s("o<w>"),O:s("o<p>"),r:s("o<+item,matchPosition(w,A)>"),s:s("o<d>"),b:s("o<@>"),t:s("o<b>"),T:s("aQ"),m:s("p"),g:s("a1"),p:s("D<@>"),B:s("N<b6,@>"),j:s("f<@>"),a:s("x<d,@>"),V:s("ak<+item,matchPosition(w,A),w>"),P:s("u"),K:s("l"),L:s("ka"),d:s("+()"),F:s("el"),l:s("a4"),N:s("d"),k:s("j"),c:s("R"),D:s("al"),o:s("ax"),h:s("a7<d,d>"),R:s("c3"),e:s("v<@>"),y:s("jD"),i:s("t"),z:s("@"),v:s("@(l)"),C:s("@(l,a4)"),S:s("b"),A:s("0&*"),_:s("l*"),W:s("a0<u>?"),X:s("l?"),H:s("jY")}})();(function constants(){var s=hunkHelpers.makeConstList
B.I=J.bG.prototype
B.b=J.o.prototype
B.c=J.aP.prototype
B.a=J.ai.prototype
B.J=J.a1.prototype
B.K=J.aT.prototype
B.ab=A.b0.prototype
B.w=J.bX.prototype
B.j=J.ax.prototype
B.at=new A.cr()
B.x=new A.cq()
B.au=new A.cy()
B.k=new A.cx()
B.l=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.y=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.D=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.z=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.C=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.B=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.A=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.m=function(hooks) { return hooks; }

B.E=new A.cH()
B.F=new A.bW()
B.i=new A.cR()
B.e=new A.d0()
B.G=new A.d2()
B.n=new A.dp()
B.d=new A.dq()
B.H=new A.cj()
B.L=new A.cI(null)
B.a8=A.h(s([0,0,32722,12287,65534,34815,65534,18431]),t.t)
B.f=A.h(s([0,0,65490,45055,65535,34815,65534,18431]),t.t)
B.a9=A.h(s([0,0,32754,11263,65534,34815,65534,18431]),t.t)
B.o=A.h(s([0,0,26624,1023,65534,2047,65534,2047]),t.t)
B.p=A.h(s([0,0,65490,12287,65535,34815,65534,18431]),t.t)
B.M=new A.m(0,"accessor")
B.N=new A.m(1,"constant")
B.Y=new A.m(2,"constructor")
B.a1=new A.m(3,"class_")
B.a2=new A.m(4,"dynamic")
B.a3=new A.m(5,"enum_")
B.a4=new A.m(6,"extension")
B.a5=new A.m(7,"extensionType")
B.a6=new A.m(8,"function")
B.a7=new A.m(9,"library")
B.O=new A.m(10,"method")
B.P=new A.m(11,"mixin")
B.Q=new A.m(12,"never")
B.R=new A.m(13,"package")
B.S=new A.m(14,"parameter")
B.T=new A.m(15,"prefix")
B.U=new A.m(16,"property")
B.V=new A.m(17,"sdk")
B.W=new A.m(18,"topic")
B.X=new A.m(19,"topLevelConstant")
B.Z=new A.m(20,"topLevelProperty")
B.a_=new A.m(21,"typedef")
B.a0=new A.m(22,"typeParameter")
B.q=A.h(s([B.M,B.N,B.Y,B.a1,B.a2,B.a3,B.a4,B.a5,B.a6,B.a7,B.O,B.P,B.Q,B.R,B.S,B.T,B.U,B.V,B.W,B.X,B.Z,B.a_,B.a0]),A.bt("o<m>"))
B.r=A.h(s([0,0,32776,33792,1,10240,0,0]),t.t)
B.t=A.h(s([]),t.b)
B.h=A.h(s([0,0,24576,1023,65534,34815,65534,18431]),t.t)
B.v={}
B.aa=new A.ah(B.v,[],A.bt("ah<d,d>"))
B.u=new A.ah(B.v,[],A.bt("ah<b6,@>"))
B.ac=new A.a5("call")
B.ad=A.K("k6")
B.ae=A.K("k7")
B.af=A.K("hJ")
B.ag=A.K("hK")
B.ah=A.K("hM")
B.ai=A.K("hN")
B.aj=A.K("hO")
B.ak=A.K("l")
B.al=A.K("i7")
B.am=A.K("i8")
B.an=A.K("i9")
B.ao=A.K("al")
B.ap=new A.d1(!1)
B.aq=new A.A(0,"isExactly")
B.ar=new A.A(1,"startsWith")
B.as=new A.A(2,"contains")})();(function staticFields(){$.dm=null
$.ap=A.h([],A.bt("o<l>"))
$.f2=null
$.eR=null
$.eQ=null
$.h2=null
$.h_=null
$.h7=null
$.dZ=null
$.e9=null
$.eH=null
$.dn=A.h([],A.bt("o<f<l>?>"))
$.aB=null
$.br=null
$.bs=null
$.eA=!1
$.r=B.d
$.eD=10
$.dX=0
$.bq=A.ej(t.N,t.m)})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal
s($,"k8","eK",()=>A.jK("_$dart_dartClosure"))
s($,"kc","ha",()=>A.S(A.cV({
toString:function(){return"$receiver$"}})))
s($,"kd","hb",()=>A.S(A.cV({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"ke","hc",()=>A.S(A.cV(null)))
s($,"kf","hd",()=>A.S(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"ki","hg",()=>A.S(A.cV(void 0)))
s($,"kj","hh",()=>A.S(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"kh","hf",()=>A.S(A.fd(null)))
s($,"kg","he",()=>A.S(function(){try{null.$method$}catch(r){return r.message}}()))
s($,"kl","hj",()=>A.S(A.fd(void 0)))
s($,"kk","hi",()=>A.S(function(){try{(void 0).$method$}catch(r){return r.message}}()))
s($,"km","eL",()=>A.ib())
s($,"ks","hp",()=>A.hY(4096))
s($,"kq","hn",()=>new A.dG().$0())
s($,"kr","ho",()=>new A.dF().$0())
s($,"kn","hk",()=>A.hX(A.j0(A.h([-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-1,-2,-2,-2,-2,-2,62,-2,62,-2,63,52,53,54,55,56,57,58,59,60,61,-2,-2,-2,-1,-2,-2,-2,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-2,-2,-2,-2,63,-2,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-2,-2,-2,-2,-2],t.t))))
s($,"ko","hl",()=>A.f6("^[\\-\\.0-9A-Z_a-z~]*$",!0))
s($,"kp","hm",()=>typeof URLSearchParams=="function")
s($,"kE","ee",()=>A.h5(B.ak))
s($,"kG","hq",()=>A.j_())
s($,"kF","bw",()=>new A.dT().$0())})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.bM,ArrayBufferView:A.aZ,DataView:A.bN,Float32Array:A.bO,Float64Array:A.bP,Int16Array:A.bQ,Int32Array:A.bR,Int8Array:A.bS,Uint16Array:A.bT,Uint32Array:A.bU,Uint8ClampedArray:A.b_,CanvasPixelArray:A.b_,Uint8Array:A.b0})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.aw.$nativeSuperclassTag="ArrayBufferView"
A.bb.$nativeSuperclassTag="ArrayBufferView"
A.bc.$nativeSuperclassTag="ArrayBufferView"
A.aX.$nativeSuperclassTag="ArrayBufferView"
A.bd.$nativeSuperclassTag="ArrayBufferView"
A.be.$nativeSuperclassTag="ArrayBufferView"
A.aY.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.jW
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=docs.dart.js.map
