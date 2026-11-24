import{aW as St,aX as Ct,g as pe,s as ve,q as xe,p as Te,a as be,b as we,_ as l,c as dt,j as vt,d as _e,a_ as U,l as ot,k as De,o as Se,r as Ce,z as Me}from"../app.BVc2p_A7.js";import{t as Ee,m as Ie,a as Ye,l as Ae,h as $e,c as Xt,d as qt,e as Fe,g as Le,i as Oe,j as We,k as Ve,n as Pe,p as ze,q as Ut,r as Zt,s as Qt,u as Kt,v as Jt}from"./d3-scale.DlYbYB9H.js";import"./framework.Bqo7-qSd.js";import"./theme.QRdgZEO8.js";function Re(t){return t}var Tt=1,Et=2,Yt=3,xt=4,te=1e-6;function Ne(t){return"translate("+t+",0)"}function He(t){return"translate(0,"+t+")"}function Be(t){return e=>+t(e)}function Ge(t,e){return e=Math.max(0,t.bandwidth()-e*2)/2,t.round()&&(e=Math.round(e)),r=>+t(r)+e}function je(){return!this.__axis}function ie(t,e){var r=[],s=null,n=null,g=6,y=6,b=3,C=typeof window<"u"&&window.devicePixelRatio>1?0:.5,L=t===Tt||t===xt?-1:1,w=t===xt||t===Et?"x":"y",V=t===Tt||t===Yt?Ne:He;function _(D){var j=s??(e.ticks?e.ticks.apply(e,r):e.domain()),N=n??(e.tickFormat?e.tickFormat.apply(e,r):Re),k=Math.max(g,0)+b,M=e.range(),W=+M[0]+C,O=+M[M.length-1]+C,H=(e.bandwidth?Ge:Be)(e.copy(),C),R=D.selection?D.selection():D,I=R.selectAll(".domain").data([null]),x=R.selectAll(".tick").data(j,e).order(),h=x.exit(),E=x.enter().append("g").attr("class","tick"),f=x.select("line"),T=x.select("text");I=I.merge(I.enter().insert("path",".tick").attr("class","domain").attr("stroke","currentColor")),x=x.merge(E),f=f.merge(E.append("line").attr("stroke","currentColor").attr(w+"2",L*g)),T=T.merge(E.append("text").attr("fill","currentColor").attr(w,L*k).attr("dy",t===Tt?"0em":t===Yt?"0.71em":"0.32em")),D!==R&&(I=I.transition(D),x=x.transition(D),f=f.transition(D),T=T.transition(D),h=h.transition(D).attr("opacity",te).attr("transform",function(v){return isFinite(v=H(v))?V(v+C):this.getAttribute("transform")}),E.attr("opacity",te).attr("transform",function(v){var p=this.parentNode.__axis;return V((p&&isFinite(p=p(v))?p:H(v))+C)})),h.remove(),I.attr("d",t===xt||t===Et?y?"M"+L*y+","+W+"H"+C+"V"+O+"H"+L*y:"M"+C+","+W+"V"+O:y?"M"+W+","+L*y+"V"+C+"H"+O+"V"+L*y:"M"+W+","+C+"H"+O),x.attr("opacity",1).attr("transform",function(v){return V(H(v)+C)}),f.attr(w+"2",L*g),T.attr(w,L*k).text(N),R.filter(je).attr("fill","none").attr("font-size",10).attr("font-family","sans-serif").attr("text-anchor",t===Et?"start":t===xt?"end":"middle"),R.each(function(){this.__axis=H})}return _.scale=function(D){return arguments.length?(e=D,_):e},_.ticks=function(){return r=Array.from(arguments),_},_.tickArguments=function(D){return arguments.length?(r=D==null?[]:Array.from(D),_):r.slice()},_.tickValues=function(D){return arguments.length?(s=D==null?null:Array.from(D),_):s&&s.slice()},_.tickFormat=function(D){return arguments.length?(n=D,_):n},_.tickSize=function(D){return arguments.length?(g=y=+D,_):g},_.tickSizeInner=function(D){return arguments.length?(g=+D,_):g},_.tickSizeOuter=function(D){return arguments.length?(y=+D,_):y},_.tickPadding=function(D){return arguments.length?(b=+D,_):b},_.offset=function(D){return arguments.length?(C=+D,_):C},_}function Xe(t){return ie(Tt,t)}function qe(t){return ie(Yt,t)}var ne={exports:{}};(function(t,e){(function(r,s){t.exports=s()})(St,function(){var r="day";return function(s,n,g){var y=function(L){return L.add(4-L.isoWeekday(),r)},b=n.prototype;b.isoWeekYear=function(){return y(this).year()},b.isoWeek=function(L){if(!this.$utils().u(L))return this.add(7*(L-this.isoWeek()),r);var w,V,_,D,j=y(this),N=(w=this.isoWeekYear(),V=this.$u,_=(V?g.utc:g)().year(w).startOf("year"),D=4-_.isoWeekday(),_.isoWeekday()>4&&(D+=7),_.add(D,r));return j.diff(N,"week")+1},b.isoWeekday=function(L){return this.$utils().u(L)?this.day()||7:this.day(this.day()%7?L:L-7)};var C=b.startOf;b.startOf=function(L,w){var V=this.$utils(),_=!!V.u(w)||w;return V.p(L)==="isoweek"?_?this.date(this.date()-(this.isoWeekday()-1)).startOf("day"):this.date(this.date()-1-(this.isoWeekday()-1)+7).endOf("day"):C.bind(this)(L,w)}}})})(ne);var Ue=ne.exports;const Ze=Ct(Ue);var ae={exports:{}};(function(t,e){(function(r,s){t.exports=s()})(St,function(){var r={LTS:"h:mm:ss A",LT:"h:mm A",L:"MM/DD/YYYY",LL:"MMMM D, YYYY",LLL:"MMMM D, YYYY h:mm A",LLLL:"dddd, MMMM D, YYYY h:mm A"},s=/(\[[^[]*\])|([-_:/.,()\s]+)|(A|a|Q|YYYY|YY?|ww?|MM?M?M?|Do|DD?|hh?|HH?|mm?|ss?|S{1,3}|z|ZZ?)/g,n=/\d/,g=/\d\d/,y=/\d\d?/,b=/\d*[^-_:/,()\s\d]+/,C={},L=function(k){return(k=+k)+(k>68?1900:2e3)},w=function(k){return function(M){this[k]=+M}},V=[/[+-]\d\d:?(\d\d)?|Z/,function(k){(this.zone||(this.zone={})).offset=function(M){if(!M||M==="Z")return 0;var W=M.match(/([+-]|\d\d)/g),O=60*W[1]+(+W[2]||0);return O===0?0:W[0]==="+"?-O:O}(k)}],_=function(k){var M=C[k];return M&&(M.indexOf?M:M.s.concat(M.f))},D=function(k,M){var W,O=C.meridiem;if(O){for(var H=1;H<=24;H+=1)if(k.indexOf(O(H,0,M))>-1){W=H>12;break}}else W=k===(M?"pm":"PM");return W},j={A:[b,function(k){this.afternoon=D(k,!1)}],a:[b,function(k){this.afternoon=D(k,!0)}],Q:[n,function(k){this.month=3*(k-1)+1}],S:[n,function(k){this.milliseconds=100*+k}],SS:[g,function(k){this.milliseconds=10*+k}],SSS:[/\d{3}/,function(k){this.milliseconds=+k}],s:[y,w("seconds")],ss:[y,w("seconds")],m:[y,w("minutes")],mm:[y,w("minutes")],H:[y,w("hours")],h:[y,w("hours")],HH:[y,w("hours")],hh:[y,w("hours")],D:[y,w("day")],DD:[g,w("day")],Do:[b,function(k){var M=C.ordinal,W=k.match(/\d+/);if(this.day=W[0],M)for(var O=1;O<=31;O+=1)M(O).replace(/\[|\]/g,"")===k&&(this.day=O)}],w:[y,w("week")],ww:[g,w("week")],M:[y,w("month")],MM:[g,w("month")],MMM:[b,function(k){var M=_("months"),W=(_("monthsShort")||M.map(function(O){return O.slice(0,3)})).indexOf(k)+1;if(W<1)throw new Error;this.month=W%12||W}],MMMM:[b,function(k){var M=_("months").indexOf(k)+1;if(M<1)throw new Error;this.month=M%12||M}],Y:[/[+-]?\d+/,w("year")],YY:[g,function(k){this.year=L(k)}],YYYY:[/\d{4}/,w("year")],Z:V,ZZ:V};function N(k){var M,W;M=k,W=C&&C.formats;for(var O=(k=M.replace(/(\[[^\]]+])|(LTS?|l{1,4}|L{1,4})/g,function(f,T,v){var p=v&&v.toUpperCase();return T||W[v]||r[v]||W[p].replace(/(\[[^\]]+])|(MMMM|MM|DD|dddd)/g,function(a,d,m){return d||m.slice(1)})})).match(s),H=O.length,R=0;R<H;R+=1){var I=O[R],x=j[I],h=x&&x[0],E=x&&x[1];O[R]=E?{regex:h,parser:E}:I.replace(/^\[|\]$/g,"")}return function(f){for(var T={},v=0,p=0;v<H;v+=1){var a=O[v];if(typeof a=="string")p+=a.length;else{var d=a.regex,m=a.parser,u=f.slice(p),S=d.exec(u)[0];m.call(T,S),f=f.replace(S,"")}}return function(i){var Y=i.afternoon;if(Y!==void 0){var o=i.hours;Y?o<12&&(i.hours+=12):o===12&&(i.hours=0),delete i.afternoon}}(T),T}}return function(k,M,W){W.p.customParseFormat=!0,k&&k.parseTwoDigitYear&&(L=k.parseTwoDigitYear);var O=M.prototype,H=O.parse;O.parse=function(R){var I=R.date,x=R.utc,h=R.args;this.$u=x;var E=h[1];if(typeof E=="string"){var f=h[2]===!0,T=h[3]===!0,v=f||T,p=h[2];T&&(p=h[2]),C=this.$locale(),!f&&p&&(C=W.Ls[p]),this.$d=function(u,S,i,Y){try{if(["x","X"].indexOf(S)>-1)return new Date((S==="X"?1e3:1)*u);var o=N(S)(u),G=o.year,c=o.month,A=o.day,$=o.hours,z=o.minutes,F=o.seconds,B=o.milliseconds,P=o.zone,rt=o.week,nt=new Date,yt=A||(G||c?1:nt.getDate()),lt=G||nt.getFullYear(),X=0;G&&!c||(X=c>0?c-1:nt.getMonth());var K,Z=$||0,at=z||0,J=F||0,it=B||0;return P?new Date(Date.UTC(lt,X,yt,Z,at,J,it+60*P.offset*1e3)):i?new Date(Date.UTC(lt,X,yt,Z,at,J,it)):(K=new Date(lt,X,yt,Z,at,J,it),rt&&(K=Y(K).week(rt).toDate()),K)}catch{return new Date("")}}(I,E,x,W),this.init(),p&&p!==!0&&(this.$L=this.locale(p).$L),v&&I!=this.format(E)&&(this.$d=new Date("")),C={}}else if(E instanceof Array)for(var a=E.length,d=1;d<=a;d+=1){h[1]=E[d-1];var m=W.apply(this,h);if(m.isValid()){this.$d=m.$d,this.$L=m.$L,this.init();break}d===a&&(this.$d=new Date(""))}else H.call(this,R)}}})})(ae);var Qe=ae.exports;const Ke=Ct(Qe);var oe={exports:{}};(function(t,e){(function(r,s){t.exports=s()})(St,function(){return function(r,s){var n=s.prototype,g=n.format;n.format=function(y){var b=this,C=this.$locale();if(!this.isValid())return g.bind(this)(y);var L=this.$utils(),w=(y||"YYYY-MM-DDTHH:mm:ssZ").replace(/\[([^\]]+)]|Q|wo|ww|w|WW|W|zzz|z|gggg|GGGG|Do|X|x|k{1,2}|S/g,function(V){switch(V){case"Q":return Math.ceil((b.$M+1)/3);case"Do":return C.ordinal(b.$D);case"gggg":return b.weekYear();case"GGGG":return b.isoWeekYear();case"wo":return C.ordinal(b.week(),"W");case"w":case"ww":return L.s(b.week(),V==="w"?1:2,"0");case"W":case"WW":return L.s(b.isoWeek(),V==="W"?1:2,"0");case"k":case"kk":return L.s(String(b.$H===0?24:b.$H),V==="k"?1:2,"0");case"X":return Math.floor(b.$d.getTime()/1e3);case"x":return b.$d.getTime();case"z":return"["+b.offsetName()+"]";case"zzz":return"["+b.offsetName("long")+"]";default:return V}});return g.bind(this)(w)}}})})(oe);var Je=oe.exports;const ts=Ct(Je);var ce={exports:{}};(function(t,e){(function(r,s){t.exports=s()})(St,function(){var r,s,n=1e3,g=6e4,y=36e5,b=864e5,C=31536e6,L=2628e6,w=/^(-|\+)?P(?:([-+]?[0-9,.]*)Y)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)W)?(?:([-+]?[0-9,.]*)D)?(?:T(?:([-+]?[0-9,.]*)H)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)S)?)?$/,V=/\[([^\]]+)]|YYYY|YY|Y|M{1,2}|D{1,2}|H{1,2}|m{1,2}|s{1,2}|SSS/g,_={years:C,months:L,days:b,hours:y,minutes:g,seconds:n,milliseconds:1,weeks:6048e5},D=function(I){return I instanceof H},j=function(I,x,h){return new H(I,h,x.$l)},N=function(I){return s.p(I)+"s"},k=function(I){return I<0},M=function(I){return k(I)?Math.ceil(I):Math.floor(I)},W=function(I){return Math.abs(I)},O=function(I,x){return I?k(I)?{negative:!0,format:""+W(I)+x}:{negative:!1,format:""+I+x}:{negative:!1,format:""}},H=function(){function I(h,E,f){var T=this;if(this.$d={},this.$l=f,h===void 0&&(this.$ms=0,this.parseFromMilliseconds()),E)return j(h*_[N(E)],this);if(typeof h=="number")return this.$ms=h,this.parseFromMilliseconds(),this;if(typeof h=="object")return Object.keys(h).forEach(function(a){T.$d[N(a)]=h[a]}),this.calMilliseconds(),this;if(typeof h=="string"){var v=h.match(w);if(v){var p=v.slice(2).map(function(a){return a!=null?Number(a):0});return this.$d.years=p[0],this.$d.months=p[1],this.$d.weeks=p[2],this.$d.days=p[3],this.$d.hours=p[4],this.$d.minutes=p[5],this.$d.seconds=p[6],this.calMilliseconds(),this}}return this}var x=I.prototype;return x.calMilliseconds=function(){var h=this;this.$ms=Object.keys(this.$d).reduce(function(E,f){return E+(h.$d[f]||0)*_[f]},0)},x.parseFromMilliseconds=function(){var h=this.$ms;this.$d.years=M(h/C),h%=C,this.$d.months=M(h/L),h%=L,this.$d.days=M(h/b),h%=b,this.$d.hours=M(h/y),h%=y,this.$d.minutes=M(h/g),h%=g,this.$d.seconds=M(h/n),h%=n,this.$d.milliseconds=h},x.toISOString=function(){var h=O(this.$d.years,"Y"),E=O(this.$d.months,"M"),f=+this.$d.days||0;this.$d.weeks&&(f+=7*this.$d.weeks);var T=O(f,"D"),v=O(this.$d.hours,"H"),p=O(this.$d.minutes,"M"),a=this.$d.seconds||0;this.$d.milliseconds&&(a+=this.$d.milliseconds/1e3,a=Math.round(1e3*a)/1e3);var d=O(a,"S"),m=h.negative||E.negative||T.negative||v.negative||p.negative||d.negative,u=v.format||p.format||d.format?"T":"",S=(m?"-":"")+"P"+h.format+E.format+T.format+u+v.format+p.format+d.format;return S==="P"||S==="-P"?"P0D":S},x.toJSON=function(){return this.toISOString()},x.format=function(h){var E=h||"YYYY-MM-DDTHH:mm:ss",f={Y:this.$d.years,YY:s.s(this.$d.years,2,"0"),YYYY:s.s(this.$d.years,4,"0"),M:this.$d.months,MM:s.s(this.$d.months,2,"0"),D:this.$d.days,DD:s.s(this.$d.days,2,"0"),H:this.$d.hours,HH:s.s(this.$d.hours,2,"0"),m:this.$d.minutes,mm:s.s(this.$d.minutes,2,"0"),s:this.$d.seconds,ss:s.s(this.$d.seconds,2,"0"),SSS:s.s(this.$d.milliseconds,3,"0")};return E.replace(V,function(T,v){return v||String(f[T])})},x.as=function(h){return this.$ms/_[N(h)]},x.get=function(h){var E=this.$ms,f=N(h);return f==="milliseconds"?E%=1e3:E=f==="weeks"?M(E/_[f]):this.$d[f],E||0},x.add=function(h,E,f){var T;return T=E?h*_[N(E)]:D(h)?h.$ms:j(h,this).$ms,j(this.$ms+T*(f?-1:1),this)},x.subtract=function(h,E){return this.add(h,E,!0)},x.locale=function(h){var E=this.clone();return E.$l=h,E},x.clone=function(){return j(this.$ms,this)},x.humanize=function(h){return r().add(this.$ms,"ms").locale(this.$l).fromNow(!h)},x.valueOf=function(){return this.asMilliseconds()},x.milliseconds=function(){return this.get("milliseconds")},x.asMilliseconds=function(){return this.as("milliseconds")},x.seconds=function(){return this.get("seconds")},x.asSeconds=function(){return this.as("seconds")},x.minutes=function(){return this.get("minutes")},x.asMinutes=function(){return this.as("minutes")},x.hours=function(){return this.get("hours")},x.asHours=function(){return this.as("hours")},x.days=function(){return this.get("days")},x.asDays=function(){return this.as("days")},x.weeks=function(){return this.get("weeks")},x.asWeeks=function(){return this.as("weeks")},x.months=function(){return this.get("months")},x.asMonths=function(){return this.as("months")},x.years=function(){return this.get("years")},x.asYears=function(){return this.as("years")},I}(),R=function(I,x,h){return I.add(x.years()*h,"y").add(x.months()*h,"M").add(x.days()*h,"d").add(x.hours()*h,"h").add(x.minutes()*h,"m").add(x.seconds()*h,"s").add(x.milliseconds()*h,"ms")};return function(I,x,h){r=h,s=h().$utils(),h.duration=function(T,v){var p=h.locale();return j(T,{$l:p},v)},h.isDuration=D;var E=x.prototype.add,f=x.prototype.subtract;x.prototype.add=function(T,v){return D(T)?R(this,T,1):E.bind(this)(T,v)},x.prototype.subtract=function(T,v){return D(T)?R(this,T,-1):f.bind(this)(T,v)}}})})(ce);var es=ce.exports;const ss=Ct(es);var At=function(){var t=l(function(p,a,d,m){for(d=d||{},m=p.length;m--;d[p[m]]=a);return d},"o"),e=[6,8,10,12,13,14,15,16,17,18,20,21,22,23,24,25,26,27,28,29,30,31,33,35,36,38,40],r=[1,26],s=[1,27],n=[1,28],g=[1,29],y=[1,30],b=[1,31],C=[1,32],L=[1,33],w=[1,34],V=[1,9],_=[1,10],D=[1,11],j=[1,12],N=[1,13],k=[1,14],M=[1,15],W=[1,16],O=[1,19],H=[1,20],R=[1,21],I=[1,22],x=[1,23],h=[1,25],E=[1,35],f={trace:l(function(){},"trace"),yy:{},symbols_:{error:2,start:3,gantt:4,document:5,EOF:6,line:7,SPACE:8,statement:9,NL:10,weekday:11,weekday_monday:12,weekday_tuesday:13,weekday_wednesday:14,weekday_thursday:15,weekday_friday:16,weekday_saturday:17,weekday_sunday:18,weekend:19,weekend_friday:20,weekend_saturday:21,dateFormat:22,inclusiveEndDates:23,topAxis:24,axisFormat:25,tickInterval:26,excludes:27,includes:28,todayMarker:29,title:30,acc_title:31,acc_title_value:32,acc_descr:33,acc_descr_value:34,acc_descr_multiline_value:35,section:36,clickStatement:37,taskTxt:38,taskData:39,click:40,callbackname:41,callbackargs:42,href:43,clickStatementDebug:44,$accept:0,$end:1},terminals_:{2:"error",4:"gantt",6:"EOF",8:"SPACE",10:"NL",12:"weekday_monday",13:"weekday_tuesday",14:"weekday_wednesday",15:"weekday_thursday",16:"weekday_friday",17:"weekday_saturday",18:"weekday_sunday",20:"weekend_friday",21:"weekend_saturday",22:"dateFormat",23:"inclusiveEndDates",24:"topAxis",25:"axisFormat",26:"tickInterval",27:"excludes",28:"includes",29:"todayMarker",30:"title",31:"acc_title",32:"acc_title_value",33:"acc_descr",34:"acc_descr_value",35:"acc_descr_multiline_value",36:"section",38:"taskTxt",39:"taskData",40:"click",41:"callbackname",42:"callbackargs",43:"href"},productions_:[0,[3,3],[5,0],[5,2],[7,2],[7,1],[7,1],[7,1],[11,1],[11,1],[11,1],[11,1],[11,1],[11,1],[11,1],[19,1],[19,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,1],[9,2],[9,2],[9,1],[9,1],[9,1],[9,2],[37,2],[37,3],[37,3],[37,4],[37,3],[37,4],[37,2],[44,2],[44,3],[44,3],[44,4],[44,3],[44,4],[44,2]],performAction:l(function(a,d,m,u,S,i,Y){var o=i.length-1;switch(S){case 1:return i[o-1];case 2:this.$=[];break;case 3:i[o-1].push(i[o]),this.$=i[o-1];break;case 4:case 5:this.$=i[o];break;case 6:case 7:this.$=[];break;case 8:u.setWeekday("monday");break;case 9:u.setWeekday("tuesday");break;case 10:u.setWeekday("wednesday");break;case 11:u.setWeekday("thursday");break;case 12:u.setWeekday("friday");break;case 13:u.setWeekday("saturday");break;case 14:u.setWeekday("sunday");break;case 15:u.setWeekend("friday");break;case 16:u.setWeekend("saturday");break;case 17:u.setDateFormat(i[o].substr(11)),this.$=i[o].substr(11);break;case 18:u.enableInclusiveEndDates(),this.$=i[o].substr(18);break;case 19:u.TopAxis(),this.$=i[o].substr(8);break;case 20:u.setAxisFormat(i[o].substr(11)),this.$=i[o].substr(11);break;case 21:u.setTickInterval(i[o].substr(13)),this.$=i[o].substr(13);break;case 22:u.setExcludes(i[o].substr(9)),this.$=i[o].substr(9);break;case 23:u.setIncludes(i[o].substr(9)),this.$=i[o].substr(9);break;case 24:u.setTodayMarker(i[o].substr(12)),this.$=i[o].substr(12);break;case 27:u.setDiagramTitle(i[o].substr(6)),this.$=i[o].substr(6);break;case 28:this.$=i[o].trim(),u.setAccTitle(this.$);break;case 29:case 30:this.$=i[o].trim(),u.setAccDescription(this.$);break;case 31:u.addSection(i[o].substr(8)),this.$=i[o].substr(8);break;case 33:u.addTask(i[o-1],i[o]),this.$="task";break;case 34:this.$=i[o-1],u.setClickEvent(i[o-1],i[o],null);break;case 35:this.$=i[o-2],u.setClickEvent(i[o-2],i[o-1],i[o]);break;case 36:this.$=i[o-2],u.setClickEvent(i[o-2],i[o-1],null),u.setLink(i[o-2],i[o]);break;case 37:this.$=i[o-3],u.setClickEvent(i[o-3],i[o-2],i[o-1]),u.setLink(i[o-3],i[o]);break;case 38:this.$=i[o-2],u.setClickEvent(i[o-2],i[o],null),u.setLink(i[o-2],i[o-1]);break;case 39:this.$=i[o-3],u.setClickEvent(i[o-3],i[o-1],i[o]),u.setLink(i[o-3],i[o-2]);break;case 40:this.$=i[o-1],u.setLink(i[o-1],i[o]);break;case 41:case 47:this.$=i[o-1]+" "+i[o];break;case 42:case 43:case 45:this.$=i[o-2]+" "+i[o-1]+" "+i[o];break;case 44:case 46:this.$=i[o-3]+" "+i[o-2]+" "+i[o-1]+" "+i[o];break}},"anonymous"),table:[{3:1,4:[1,2]},{1:[3]},t(e,[2,2],{5:3}),{6:[1,4],7:5,8:[1,6],9:7,10:[1,8],11:17,12:r,13:s,14:n,15:g,16:y,17:b,18:C,19:18,20:L,21:w,22:V,23:_,24:D,25:j,26:N,27:k,28:M,29:W,30:O,31:H,33:R,35:I,36:x,37:24,38:h,40:E},t(e,[2,7],{1:[2,1]}),t(e,[2,3]),{9:36,11:17,12:r,13:s,14:n,15:g,16:y,17:b,18:C,19:18,20:L,21:w,22:V,23:_,24:D,25:j,26:N,27:k,28:M,29:W,30:O,31:H,33:R,35:I,36:x,37:24,38:h,40:E},t(e,[2,5]),t(e,[2,6]),t(e,[2,17]),t(e,[2,18]),t(e,[2,19]),t(e,[2,20]),t(e,[2,21]),t(e,[2,22]),t(e,[2,23]),t(e,[2,24]),t(e,[2,25]),t(e,[2,26]),t(e,[2,27]),{32:[1,37]},{34:[1,38]},t(e,[2,30]),t(e,[2,31]),t(e,[2,32]),{39:[1,39]},t(e,[2,8]),t(e,[2,9]),t(e,[2,10]),t(e,[2,11]),t(e,[2,12]),t(e,[2,13]),t(e,[2,14]),t(e,[2,15]),t(e,[2,16]),{41:[1,40],43:[1,41]},t(e,[2,4]),t(e,[2,28]),t(e,[2,29]),t(e,[2,33]),t(e,[2,34],{42:[1,42],43:[1,43]}),t(e,[2,40],{41:[1,44]}),t(e,[2,35],{43:[1,45]}),t(e,[2,36]),t(e,[2,38],{42:[1,46]}),t(e,[2,37]),t(e,[2,39])],defaultActions:{},parseError:l(function(a,d){if(d.recoverable)this.trace(a);else{var m=new Error(a);throw m.hash=d,m}},"parseError"),parse:l(function(a){var d=this,m=[0],u=[],S=[null],i=[],Y=this.table,o="",G=0,c=0,A=2,$=1,z=i.slice.call(arguments,1),F=Object.create(this.lexer),B={yy:{}};for(var P in this.yy)Object.prototype.hasOwnProperty.call(this.yy,P)&&(B.yy[P]=this.yy[P]);F.setInput(a,B.yy),B.yy.lexer=F,B.yy.parser=this,typeof F.yylloc>"u"&&(F.yylloc={});var rt=F.yylloc;i.push(rt);var nt=F.options&&F.options.ranges;typeof B.yy.parseError=="function"?this.parseError=B.yy.parseError:this.parseError=Object.getPrototypeOf(this).parseError;function yt(Q){m.length=m.length-2*Q,S.length=S.length-Q,i.length=i.length-Q}l(yt,"popStack");function lt(){var Q;return Q=u.pop()||F.lex()||$,typeof Q!="number"&&(Q instanceof Array&&(u=Q,Q=u.pop()),Q=d.symbols_[Q]||Q),Q}l(lt,"lex");for(var X,K,Z,at,J={},it,tt,jt,pt;;){if(K=m[m.length-1],this.defaultActions[K]?Z=this.defaultActions[K]:((X===null||typeof X>"u")&&(X=lt()),Z=Y[K]&&Y[K][X]),typeof Z>"u"||!Z.length||!Z[0]){var Mt="";pt=[];for(it in Y[K])this.terminals_[it]&&it>A&&pt.push("'"+this.terminals_[it]+"'");F.showPosition?Mt="Parse error on line "+(G+1)+`:
`+F.showPosition()+`
Expecting `+pt.join(", ")+", got '"+(this.terminals_[X]||X)+"'":Mt="Parse error on line "+(G+1)+": Unexpected "+(X==$?"end of input":"'"+(this.terminals_[X]||X)+"'"),this.parseError(Mt,{text:F.match,token:this.terminals_[X]||X,line:F.yylineno,loc:rt,expected:pt})}if(Z[0]instanceof Array&&Z.length>1)throw new Error("Parse Error: multiple actions possible at state: "+K+", token: "+X);switch(Z[0]){case 1:m.push(X),S.push(F.yytext),i.push(F.yylloc),m.push(Z[1]),X=null,c=F.yyleng,o=F.yytext,G=F.yylineno,rt=F.yylloc;break;case 2:if(tt=this.productions_[Z[1]][1],J.$=S[S.length-tt],J._$={first_line:i[i.length-(tt||1)].first_line,last_line:i[i.length-1].last_line,first_column:i[i.length-(tt||1)].first_column,last_column:i[i.length-1].last_column},nt&&(J._$.range=[i[i.length-(tt||1)].range[0],i[i.length-1].range[1]]),at=this.performAction.apply(J,[o,c,G,B.yy,Z[1],S,i].concat(z)),typeof at<"u")return at;tt&&(m=m.slice(0,-1*tt*2),S=S.slice(0,-1*tt),i=i.slice(0,-1*tt)),m.push(this.productions_[Z[1]][0]),S.push(J.$),i.push(J._$),jt=Y[m[m.length-2]][m[m.length-1]],m.push(jt);break;case 3:return!0}}return!0},"parse")},T=function(){var p={EOF:1,parseError:l(function(d,m){if(this.yy.parser)this.yy.parser.parseError(d,m);else throw new Error(d)},"parseError"),setInput:l(function(a,d){return this.yy=d||this.yy||{},this._input=a,this._more=this._backtrack=this.done=!1,this.yylineno=this.yyleng=0,this.yytext=this.matched=this.match="",this.conditionStack=["INITIAL"],this.yylloc={first_line:1,first_column:0,last_line:1,last_column:0},this.options.ranges&&(this.yylloc.range=[0,0]),this.offset=0,this},"setInput"),input:l(function(){var a=this._input[0];this.yytext+=a,this.yyleng++,this.offset++,this.match+=a,this.matched+=a;var d=a.match(/(?:\r\n?|\n).*/g);return d?(this.yylineno++,this.yylloc.last_line++):this.yylloc.last_column++,this.options.ranges&&this.yylloc.range[1]++,this._input=this._input.slice(1),a},"input"),unput:l(function(a){var d=a.length,m=a.split(/(?:\r\n?|\n)/g);this._input=a+this._input,this.yytext=this.yytext.substr(0,this.yytext.length-d),this.offset-=d;var u=this.match.split(/(?:\r\n?|\n)/g);this.match=this.match.substr(0,this.match.length-1),this.matched=this.matched.substr(0,this.matched.length-1),m.length-1&&(this.yylineno-=m.length-1);var S=this.yylloc.range;return this.yylloc={first_line:this.yylloc.first_line,last_line:this.yylineno+1,first_column:this.yylloc.first_column,last_column:m?(m.length===u.length?this.yylloc.first_column:0)+u[u.length-m.length].length-m[0].length:this.yylloc.first_column-d},this.options.ranges&&(this.yylloc.range=[S[0],S[0]+this.yyleng-d]),this.yyleng=this.yytext.length,this},"unput"),more:l(function(){return this._more=!0,this},"more"),reject:l(function(){if(this.options.backtrack_lexer)this._backtrack=!0;else return this.parseError("Lexical error on line "+(this.yylineno+1)+`. You can only invoke reject() in the lexer when the lexer is of the backtracking persuasion (options.backtrack_lexer = true).
`+this.showPosition(),{text:"",token:null,line:this.yylineno});return this},"reject"),less:l(function(a){this.unput(this.match.slice(a))},"less"),pastInput:l(function(){var a=this.matched.substr(0,this.matched.length-this.match.length);return(a.length>20?"...":"")+a.substr(-20).replace(/\n/g,"")},"pastInput"),upcomingInput:l(function(){var a=this.match;return a.length<20&&(a+=this._input.substr(0,20-a.length)),(a.substr(0,20)+(a.length>20?"...":"")).replace(/\n/g,"")},"upcomingInput"),showPosition:l(function(){var a=this.pastInput(),d=new Array(a.length+1).join("-");return a+this.upcomingInput()+`
`+d+"^"},"showPosition"),test_match:l(function(a,d){var m,u,S;if(this.options.backtrack_lexer&&(S={yylineno:this.yylineno,yylloc:{first_line:this.yylloc.first_line,last_line:this.last_line,first_column:this.yylloc.first_column,last_column:this.yylloc.last_column},yytext:this.yytext,match:this.match,matches:this.matches,matched:this.matched,yyleng:this.yyleng,offset:this.offset,_more:this._more,_input:this._input,yy:this.yy,conditionStack:this.conditionStack.slice(0),done:this.done},this.options.ranges&&(S.yylloc.range=this.yylloc.range.slice(0))),u=a[0].match(/(?:\r\n?|\n).*/g),u&&(this.yylineno+=u.length),this.yylloc={first_line:this.yylloc.last_line,last_line:this.yylineno+1,first_column:this.yylloc.last_column,last_column:u?u[u.length-1].length-u[u.length-1].match(/\r?\n?/)[0].length:this.yylloc.last_column+a[0].length},this.yytext+=a[0],this.match+=a[0],this.matches=a,this.yyleng=this.yytext.length,this.options.ranges&&(this.yylloc.range=[this.offset,this.offset+=this.yyleng]),this._more=!1,this._backtrack=!1,this._input=this._input.slice(a[0].length),this.matched+=a[0],m=this.performAction.call(this,this.yy,this,d,this.conditionStack[this.conditionStack.length-1]),this.done&&this._input&&(this.done=!1),m)return m;if(this._backtrack){for(var i in S)this[i]=S[i];return!1}return!1},"test_match"),next:l(function(){if(this.done)return this.EOF;this._input||(this.done=!0);var a,d,m,u;this._more||(this.yytext="",this.match="");for(var S=this._currentRules(),i=0;i<S.length;i++)if(m=this._input.match(this.rules[S[i]]),m&&(!d||m[0].length>d[0].length)){if(d=m,u=i,this.options.backtrack_lexer){if(a=this.test_match(m,S[i]),a!==!1)return a;if(this._backtrack){d=!1;continue}else return!1}else if(!this.options.flex)break}return d?(a=this.test_match(d,S[u]),a!==!1?a:!1):this._input===""?this.EOF:this.parseError("Lexical error on line "+(this.yylineno+1)+`. Unrecognized text.
`+this.showPosition(),{text:"",token:null,line:this.yylineno})},"next"),lex:l(function(){var d=this.next();return d||this.lex()},"lex"),begin:l(function(d){this.conditionStack.push(d)},"begin"),popState:l(function(){var d=this.conditionStack.length-1;return d>0?this.conditionStack.pop():this.conditionStack[0]},"popState"),_currentRules:l(function(){return this.conditionStack.length&&this.conditionStack[this.conditionStack.length-1]?this.conditions[this.conditionStack[this.conditionStack.length-1]].rules:this.conditions.INITIAL.rules},"_currentRules"),topState:l(function(d){return d=this.conditionStack.length-1-Math.abs(d||0),d>=0?this.conditionStack[d]:"INITIAL"},"topState"),pushState:l(function(d){this.begin(d)},"pushState"),stateStackSize:l(function(){return this.conditionStack.length},"stateStackSize"),options:{"case-insensitive":!0},performAction:l(function(d,m,u,S){switch(u){case 0:return this.begin("open_directive"),"open_directive";case 1:return this.begin("acc_title"),31;case 2:return this.popState(),"acc_title_value";case 3:return this.begin("acc_descr"),33;case 4:return this.popState(),"acc_descr_value";case 5:this.begin("acc_descr_multiline");break;case 6:this.popState();break;case 7:return"acc_descr_multiline_value";case 8:break;case 9:break;case 10:break;case 11:return 10;case 12:break;case 13:break;case 14:this.begin("href");break;case 15:this.popState();break;case 16:return 43;case 17:this.begin("callbackname");break;case 18:this.popState();break;case 19:this.popState(),this.begin("callbackargs");break;case 20:return 41;case 21:this.popState();break;case 22:return 42;case 23:this.begin("click");break;case 24:this.popState();break;case 25:return 40;case 26:return 4;case 27:return 22;case 28:return 23;case 29:return 24;case 30:return 25;case 31:return 26;case 32:return 28;case 33:return 27;case 34:return 29;case 35:return 12;case 36:return 13;case 37:return 14;case 38:return 15;case 39:return 16;case 40:return 17;case 41:return 18;case 42:return 20;case 43:return 21;case 44:return"date";case 45:return 30;case 46:return"accDescription";case 47:return 36;case 48:return 38;case 49:return 39;case 50:return":";case 51:return 6;case 52:return"INVALID"}},"anonymous"),rules:[/^(?:%%\{)/i,/^(?:accTitle\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*:\s*)/i,/^(?:(?!\n||)*[^\n]*)/i,/^(?:accDescr\s*\{\s*)/i,/^(?:[\}])/i,/^(?:[^\}]*)/i,/^(?:%%(?!\{)*[^\n]*)/i,/^(?:[^\}]%%*[^\n]*)/i,/^(?:%%*[^\n]*[\n]*)/i,/^(?:[\n]+)/i,/^(?:\s+)/i,/^(?:%[^\n]*)/i,/^(?:href[\s]+["])/i,/^(?:["])/i,/^(?:[^"]*)/i,/^(?:call[\s]+)/i,/^(?:\([\s]*\))/i,/^(?:\()/i,/^(?:[^(]*)/i,/^(?:\))/i,/^(?:[^)]*)/i,/^(?:click[\s]+)/i,/^(?:[\s\n])/i,/^(?:[^\s\n]*)/i,/^(?:gantt\b)/i,/^(?:dateFormat\s[^#\n;]+)/i,/^(?:inclusiveEndDates\b)/i,/^(?:topAxis\b)/i,/^(?:axisFormat\s[^#\n;]+)/i,/^(?:tickInterval\s[^#\n;]+)/i,/^(?:includes\s[^#\n;]+)/i,/^(?:excludes\s[^#\n;]+)/i,/^(?:todayMarker\s[^\n;]+)/i,/^(?:weekday\s+monday\b)/i,/^(?:weekday\s+tuesday\b)/i,/^(?:weekday\s+wednesday\b)/i,/^(?:weekday\s+thursday\b)/i,/^(?:weekday\s+friday\b)/i,/^(?:weekday\s+saturday\b)/i,/^(?:weekday\s+sunday\b)/i,/^(?:weekend\s+friday\b)/i,/^(?:weekend\s+saturday\b)/i,/^(?:\d\d\d\d-\d\d-\d\d\b)/i,/^(?:title\s[^\n]+)/i,/^(?:accDescription\s[^#\n;]+)/i,/^(?:section\s[^\n]+)/i,/^(?:[^:\n]+)/i,/^(?::[^#\n;]+)/i,/^(?::)/i,/^(?:$)/i,/^(?:.)/i],conditions:{acc_descr_multiline:{rules:[6,7],inclusive:!1},acc_descr:{rules:[4],inclusive:!1},acc_title:{rules:[2],inclusive:!1},callbackargs:{rules:[21,22],inclusive:!1},callbackname:{rules:[18,19,20],inclusive:!1},href:{rules:[15,16],inclusive:!1},click:{rules:[24,25],inclusive:!1},INITIAL:{rules:[0,1,3,5,8,9,10,11,12,13,14,17,23,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52],inclusive:!0}}};return p}();f.lexer=T;function v(){this.yy={}}return l(v,"Parser"),v.prototype=f,f.Parser=v,new v}();At.parser=At;var rs=At;U.extend(Ze);U.extend(Ke);U.extend(ts);var ee={friday:5,saturday:6},et="",Ot="",Wt=void 0,Vt="",ht=[],mt=[],Pt=new Map,zt=[],_t=[],kt="",Rt="",le=["active","done","crit","milestone","vert"],Nt=[],ut="",gt=!1,Ht=!1,Bt="sunday",Dt="saturday",$t=0,is=l(function(){zt=[],_t=[],kt="",Nt=[],bt=0,Lt=void 0,wt=void 0,q=[],et="",Ot="",Rt="",Wt=void 0,Vt="",ht=[],mt=[],gt=!1,Ht=!1,$t=0,Pt=new Map,ut="",Ce(),Bt="sunday",Dt="saturday"},"clear"),ns=l(function(t){ut=t},"setDiagramId"),as=l(function(t){Ot=t},"setAxisFormat"),os=l(function(){return Ot},"getAxisFormat"),cs=l(function(t){Wt=t},"setTickInterval"),ls=l(function(){return Wt},"getTickInterval"),us=l(function(t){Vt=t},"setTodayMarker"),ds=l(function(){return Vt},"getTodayMarker"),fs=l(function(t){et=t},"setDateFormat"),hs=l(function(){gt=!0},"enableInclusiveEndDates"),ms=l(function(){return gt},"endDatesAreInclusive"),ks=l(function(){Ht=!0},"enableTopAxis"),ys=l(function(){return Ht},"topAxisEnabled"),gs=l(function(t){Rt=t},"setDisplayMode"),ps=l(function(){return Rt},"getDisplayMode"),vs=l(function(){return et},"getDateFormat"),ue=l((t,e)=>{const r=e.toLowerCase().split(/[\s,]+/).filter(s=>s!=="");return[...new Set([...t,...r])]},"mergeTokens"),xs=l(function(t){ht=ue(ht,t)},"setIncludes"),Ts=l(function(){return ht},"getIncludes"),bs=l(function(t){mt=ue(mt,t)},"setExcludes"),ws=l(function(){return mt},"getExcludes"),_s=l(function(){return Pt},"getLinks"),Ds=l(function(t){kt=t,zt.push(t)},"addSection"),Ss=l(function(){return zt},"getSections"),Cs=l(function(){let t=se();const e=10;let r=0;for(;!t&&r<e;)t=se(),r++;return _t=q,_t},"getTasks"),de=l(function(t,e,r,s){const n=t.format(e.trim()),g=t.format("YYYY-MM-DD");return s.includes(n)||s.includes(g)?!1:r.includes("weekends")&&(t.isoWeekday()===ee[Dt]||t.isoWeekday()===ee[Dt]+1)||r.includes(t.format("dddd").toLowerCase())?!0:r.includes(n)||r.includes(g)},"isInvalidDate"),Ms=l(function(t){Bt=t},"setWeekday"),Es=l(function(){return Bt},"getWeekday"),Is=l(function(t){Dt=t},"setWeekend"),fe=l(function(t,e,r,s){if(!r.length||t.manualEndTime)return;let n;t.startTime instanceof Date?n=U(t.startTime):n=U(t.startTime,e,!0),n=n.add(1,"d");let g;t.endTime instanceof Date?g=U(t.endTime):g=U(t.endTime,e,!0);const[y,b]=Ys(n,g,e,r,s);t.endTime=y.toDate(),t.renderEndTime=b},"checkTaskDates"),Ys=l(function(t,e,r,s,n){let g=!1,y=null;const b=e.add(1e4,"d");for(;t<=e;){if(g||(y=e.toDate()),g=de(t,r,s,n),g&&(e=e.add(1,"d"),e>b))throw new Error("Failed to find a valid date that was not excluded by `excludes` after 10,000 iterations.");t=t.add(1,"d")}return[e,y]},"fixTaskDates"),Ft=l(function(t,e,r){if(r=r.trim(),l(b=>{const C=b.trim();return C==="x"||C==="X"},"isTimestampFormat")(e)&&/^\d+$/.test(r))return new Date(Number(r));const g=/^after\s+(?<ids>[\d\w- ]+)/.exec(r);if(g!==null){let b=null;for(const L of g.groups.ids.split(" ")){let w=ct(L);w!==void 0&&(!b||w.endTime>b.endTime)&&(b=w)}if(b)return b.endTime;const C=new Date;return C.setHours(0,0,0,0),C}let y=U(r,e.trim(),!0);if(y.isValid())return y.toDate();{ot.debug("Invalid date:"+r),ot.debug("With date format:"+e.trim());const b=new Date(r);if(b===void 0||isNaN(b.getTime())||b.getFullYear()<-1e4||b.getFullYear()>1e4)throw new Error("Invalid date:"+r);return b}},"getStartDate"),he=l(function(t){const e=/^(\d+(?:\.\d+)?)([Mdhmswy]|ms)$/.exec(t.trim());return e!==null?[Number.parseFloat(e[1]),e[2]]:[NaN,"ms"]},"parseDuration"),me=l(function(t,e,r,s=!1){r=r.trim();const g=/^until\s+(?<ids>[\d\w- ]+)/.exec(r);if(g!==null){let w=null;for(const _ of g.groups.ids.split(" ")){let D=ct(_);D!==void 0&&(!w||D.startTime<w.startTime)&&(w=D)}if(w)return w.startTime;const V=new Date;return V.setHours(0,0,0,0),V}let y=U(r,e.trim(),!0);if(y.isValid())return s&&(y=y.add(1,"d")),y.toDate();let b=U(t);const[C,L]=he(r);if(!Number.isNaN(C)){const w=b.add(C,L);w.isValid()&&(b=w)}return b.toDate()},"getEndDate"),bt=0,ft=l(function(t){return t===void 0?(bt=bt+1,"task"+bt):t},"parseId"),As=l(function(t,e){let r;e.substr(0,1)===":"?r=e.substr(1,e.length):r=e;const s=r.split(","),n={};Gt(s,n,le);for(let y=0;y<s.length;y++)s[y]=s[y].trim();let g="";switch(s.length){case 1:n.id=ft(),n.startTime=t.endTime,g=s[0];break;case 2:n.id=ft(),n.startTime=Ft(void 0,et,s[0]),g=s[1];break;case 3:n.id=ft(s[0]),n.startTime=Ft(void 0,et,s[1]),g=s[2];break}return g&&(n.endTime=me(n.startTime,et,g,gt),n.manualEndTime=U(g,"YYYY-MM-DD",!0).isValid(),fe(n,et,mt,ht)),n},"compileData"),$s=l(function(t,e){let r;e.substr(0,1)===":"?r=e.substr(1,e.length):r=e;const s=r.split(","),n={};Gt(s,n,le);for(let g=0;g<s.length;g++)s[g]=s[g].trim();switch(s.length){case 1:n.id=ft(),n.startTime={type:"prevTaskEnd",id:t},n.endTime={data:s[0]};break;case 2:n.id=ft(),n.startTime={type:"getStartDate",startData:s[0]},n.endTime={data:s[1]};break;case 3:n.id=ft(s[0]),n.startTime={type:"getStartDate",startData:s[1]},n.endTime={data:s[2]};break}return n},"parseData"),Lt,wt,q=[],ke={},Fs=l(function(t,e){const r={section:kt,type:kt,processed:!1,manualEndTime:!1,renderEndTime:null,raw:{data:e},task:t,classes:[]},s=$s(wt,e);r.raw.startTime=s.startTime,r.raw.endTime=s.endTime,r.id=s.id,r.prevTaskId=wt,r.active=s.active,r.done=s.done,r.crit=s.crit,r.milestone=s.milestone,r.vert=s.vert,r.vert?r.order=-1:(r.order=$t,$t++);const n=q.push(r);wt=r.id,ke[r.id]=n-1},"addTask"),ct=l(function(t){const e=ke[t];return q[e]},"findTaskById"),Ls=l(function(t,e){const r={section:kt,type:kt,description:t,task:t,classes:[]},s=As(Lt,e);r.startTime=s.startTime,r.endTime=s.endTime,r.id=s.id,r.active=s.active,r.done=s.done,r.crit=s.crit,r.milestone=s.milestone,r.vert=s.vert,Lt=r,_t.push(r)},"addTaskOrg"),se=l(function(){const t=l(function(r){const s=q[r];let n="";switch(q[r].raw.startTime.type){case"prevTaskEnd":{const g=ct(s.prevTaskId);s.startTime=g.endTime;break}case"getStartDate":n=Ft(void 0,et,q[r].raw.startTime.startData),n&&(q[r].startTime=n);break}return q[r].startTime&&(q[r].endTime=me(q[r].startTime,et,q[r].raw.endTime.data,gt),q[r].endTime&&(q[r].processed=!0,q[r].manualEndTime=U(q[r].raw.endTime.data,"YYYY-MM-DD",!0).isValid(),fe(q[r],et,mt,ht))),q[r].processed},"compileTask");let e=!0;for(const[r,s]of q.entries())t(r),e=e&&s.processed;return e},"compileTasks"),Os=l(function(t,e){let r=e;dt().securityLevel!=="loose"&&(r=Se(e)),t.split(",").forEach(function(s){ct(s)!==void 0&&(ge(s,()=>{window.open(r,"_self")}),Pt.set(s,r))}),ye(t,"clickable")},"setLink"),ye=l(function(t,e){t.split(",").forEach(function(r){let s=ct(r);s!==void 0&&s.classes.push(e)})},"setClass"),Ws=l(function(t,e,r){if(dt().securityLevel!=="loose"||e===void 0)return;let s=[];if(typeof r=="string"){s=r.split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/);for(let g=0;g<s.length;g++){let y=s[g].trim();y.startsWith('"')&&y.endsWith('"')&&(y=y.substr(1,y.length-2)),s[g]=y}}s.length===0&&s.push(t),ct(t)!==void 0&&ge(t,()=>{Me.runFunc(e,...s)})},"setClickFun"),ge=l(function(t,e){Nt.push(function(){const r=ut?`${ut}-${t}`:t,s=document.querySelector(`[id="${r}"]`);s!==null&&s.addEventListener("click",function(){e()})},function(){const r=ut?`${ut}-${t}`:t,s=document.querySelector(`[id="${r}-text"]`);s!==null&&s.addEventListener("click",function(){e()})})},"pushFun"),Vs=l(function(t,e,r){t.split(",").forEach(function(s){Ws(s,e,r)}),ye(t,"clickable")},"setClickEvent"),Ps=l(function(t){Nt.forEach(function(e){e(t)})},"bindFunctions"),zs={getConfig:l(()=>dt().gantt,"getConfig"),clear:is,setDateFormat:fs,getDateFormat:vs,enableInclusiveEndDates:hs,endDatesAreInclusive:ms,enableTopAxis:ks,topAxisEnabled:ys,setAxisFormat:as,getAxisFormat:os,setTickInterval:cs,getTickInterval:ls,setTodayMarker:us,getTodayMarker:ds,setAccTitle:we,getAccTitle:be,setDiagramTitle:Te,getDiagramTitle:xe,setDiagramId:ns,setDisplayMode:gs,getDisplayMode:ps,setAccDescription:ve,getAccDescription:pe,addSection:Ds,getSections:Ss,getTasks:Cs,addTask:Fs,findTaskById:ct,addTaskOrg:Ls,setIncludes:xs,getIncludes:Ts,setExcludes:bs,getExcludes:ws,setClickEvent:Vs,setLink:Os,getLinks:_s,bindFunctions:Ps,parseDuration:he,isInvalidDate:de,setWeekday:Ms,getWeekday:Es,setWeekend:Is};function Gt(t,e,r){let s=!0;for(;s;)s=!1,r.forEach(function(n){const g="^\\s*"+n+"\\s*$",y=new RegExp(g);t[0].match(y)&&(e[n]=!0,t.shift(1),s=!0)})}l(Gt,"getTaskTags");U.extend(ss);var Rs=l(function(){ot.debug("Something is calling, setConf, remove the call")},"setConf"),re={monday:ze,tuesday:Pe,wednesday:Ve,thursday:We,friday:Oe,saturday:Le,sunday:Fe},Ns=l((t,e)=>{let r=[...t].map(()=>-1/0),s=[...t].sort((g,y)=>g.startTime-y.startTime||g.order-y.order),n=0;for(const g of s)for(let y=0;y<r.length;y++)if(g.startTime>=r[y]){r[y]=g.endTime,g.order=y+e,y>n&&(n=y);break}return n},"getMaxIntersections"),st,It=1e4,Hs=l(function(t,e,r,s){const n=dt().gantt;s.db.setDiagramId(e);const g=dt().securityLevel;let y;g==="sandbox"&&(y=vt("#i"+e));const b=g==="sandbox"?vt(y.nodes()[0].contentDocument.body):vt("body"),C=g==="sandbox"?y.nodes()[0].contentDocument:document,L=C.getElementById(e);st=L.parentElement.offsetWidth,st===void 0&&(st=1200),n.useWidth!==void 0&&(st=n.useWidth);const w=s.db.getTasks(),V=w.filter(f=>!f.vert);let _=[];for(const f of V)_.push(f.type);_=E(_);const D={};let j=2*n.topPadding;if(s.db.getDisplayMode()==="compact"||n.displayMode==="compact"){const f={};for(const v of V)f[v.section]===void 0?f[v.section]=[v]:f[v.section].push(v);let T=0;for(const v of Object.keys(f)){const p=Ns(f[v],T)+1;T+=p,j+=p*(n.barHeight+n.barGap),D[v]=p}}else{j+=V.length*(n.barHeight+n.barGap);for(const f of _)D[f]=V.filter(T=>T.type===f).length}L.setAttribute("viewBox","0 0 "+st+" "+j);const N=b.select(`[id="${e}"]`),k=Ee().domain([Ie(w,function(f){return f.startTime}),Ye(w,function(f){return f.endTime})]).rangeRound([0,st-n.leftPadding-n.rightPadding]);function M(f,T){const v=f.startTime,p=T.startTime;let a=0;return v>p?a=1:v<p&&(a=-1),a}l(M,"taskCompare"),w.sort(M),W(w,st,j),_e(N,j,st,n.useMaxWidth),N.append("text").text(s.db.getDiagramTitle()).attr("x",st/2).attr("y",n.titleTopMargin).attr("class","titleText");function W(f,T,v){const p=n.barHeight,a=p+n.barGap,d=n.topPadding,m=n.leftPadding,u=Ae().domain([0,_.length]).range(["#00B9FA","#F95002"]).interpolate($e);H(a,d,m,T,v,f,s.db.getExcludes(),s.db.getIncludes()),I(m,d,T,v),O(f,a,d,m,p,u,T),x(a,d),h(m,d,T,v)}l(W,"makeGantt");function O(f,T,v,p,a,d,m){f.sort((c,A)=>c.vert===A.vert?0:c.vert?1:-1);const u=f.filter(c=>!c.vert),i=[...new Set(u.map(c=>c.order))].map(c=>u.find(A=>A.order===c));N.append("g").selectAll("rect").data(i).enter().append("rect").attr("x",0).attr("y",function(c,A){return A=c.order,A*T+v-2}).attr("width",function(){return m-n.rightPadding/2}).attr("height",T).attr("class",function(c){for(const[A,$]of _.entries())if(c.type===$)return"section section"+A%n.numberSectionStyles;return"section section0"}).enter();const Y=N.append("g").selectAll("rect").data(f).enter(),o=s.db.getLinks();if(Y.append("rect").attr("id",function(c){return e+"-"+c.id}).attr("rx",3).attr("ry",3).attr("x",function(c){return c.milestone?k(c.startTime)+p+.5*(k(c.endTime)-k(c.startTime))-.5*a:k(c.startTime)+p}).attr("y",function(c,A){return A=c.order,c.vert?n.gridLineStartPadding:A*T+v}).attr("width",function(c){return c.milestone?a:c.vert?.08*a:k(c.renderEndTime||c.endTime)-k(c.startTime)}).attr("height",function(c){return c.vert?u.length*(n.barHeight+n.barGap)+n.barHeight*2:a}).attr("transform-origin",function(c,A){return A=c.order,(k(c.startTime)+p+.5*(k(c.endTime)-k(c.startTime))).toString()+"px "+(A*T+v+.5*a).toString()+"px"}).attr("class",function(c){const A="task";let $="";c.classes.length>0&&($=c.classes.join(" "));let z=0;for(const[B,P]of _.entries())c.type===P&&(z=B%n.numberSectionStyles);let F="";return c.active?c.crit?F+=" activeCrit":F=" active":c.done?c.crit?F=" doneCrit":F=" done":c.crit&&(F+=" crit"),F.length===0&&(F=" task"),c.milestone&&(F=" milestone "+F),c.vert&&(F=" vert "+F),F+=z,F+=" "+$,A+F}),Y.append("text").attr("id",function(c){return e+"-"+c.id+"-text"}).text(function(c){return c.task}).attr("font-size",n.fontSize).attr("x",function(c){let A=k(c.startTime),$=k(c.renderEndTime||c.endTime);if(c.milestone&&(A+=.5*(k(c.endTime)-k(c.startTime))-.5*a,$=A+a),c.vert)return k(c.startTime)+p;const z=this.getBBox().width;return z>$-A?$+z+1.5*n.leftPadding>m?A+p-5:$+p+5:($-A)/2+A+p}).attr("y",function(c,A){return c.vert?n.gridLineStartPadding+u.length*(n.barHeight+n.barGap)+60:(A=c.order,A*T+n.barHeight/2+(n.fontSize/2-2)+v)}).attr("text-height",a).attr("class",function(c){const A=k(c.startTime);let $=k(c.endTime);c.milestone&&($=A+a);const z=this.getBBox().width;let F="";c.classes.length>0&&(F=c.classes.join(" "));let B=0;for(const[rt,nt]of _.entries())c.type===nt&&(B=rt%n.numberSectionStyles);let P="";return c.active&&(c.crit?P="activeCritText"+B:P="activeText"+B),c.done?c.crit?P=P+" doneCritText"+B:P=P+" doneText"+B:c.crit&&(P=P+" critText"+B),c.milestone&&(P+=" milestoneText"),c.vert&&(P+=" vertText"),z>$-A?$+z+1.5*n.leftPadding>m?F+" taskTextOutsideLeft taskTextOutside"+B+" "+P:F+" taskTextOutsideRight taskTextOutside"+B+" "+P+" width-"+z:F+" taskText taskText"+B+" "+P+" width-"+z}),dt().securityLevel==="sandbox"){let c;c=vt("#i"+e);const A=c.nodes()[0].contentDocument;Y.filter(function($){return o.has($.id)}).each(function($){var z=A.querySelector("#"+CSS.escape(e+"-"+$.id)),F=A.querySelector("#"+CSS.escape(e+"-"+$.id+"-text"));const B=z.parentNode;var P=A.createElement("a");P.setAttribute("xlink:href",o.get($.id)),P.setAttribute("target","_top"),B.appendChild(P),P.appendChild(z),P.appendChild(F)})}}l(O,"drawRects");function H(f,T,v,p,a,d,m,u){if(m.length===0&&u.length===0)return;let S,i;for(const{startTime:$,endTime:z}of d)(S===void 0||$<S)&&(S=$),(i===void 0||z>i)&&(i=z);if(!S||!i)return;if(U(i).diff(U(S),"year")>5){ot.warn("The difference between the min and max time is more than 5 years. This will cause performance issues. Skipping drawing exclude days.");return}const Y=s.db.getDateFormat(),o=[];let G=null,c=U(S);for(;c.valueOf()<=i;)s.db.isInvalidDate(c,Y,m,u)?G?G.end=c:G={start:c,end:c}:G&&(o.push(G),G=null),c=c.add(1,"d");N.append("g").selectAll("rect").data(o).enter().append("rect").attr("id",$=>e+"-exclude-"+$.start.format("YYYY-MM-DD")).attr("x",$=>k($.start.startOf("day"))+v).attr("y",n.gridLineStartPadding).attr("width",$=>k($.end.endOf("day"))-k($.start.startOf("day"))).attr("height",a-T-n.gridLineStartPadding).attr("transform-origin",function($,z){return(k($.start)+v+.5*(k($.end)-k($.start))).toString()+"px "+(z*f+.5*a).toString()+"px"}).attr("class","exclude-range")}l(H,"drawExcludeDays");function R(f,T,v,p){if(v<=0||f>T)return 1/0;const a=T-f,d=U.duration({[p??"day"]:v}).asMilliseconds();return d<=0?1/0:Math.ceil(a/d)}l(R,"getEstimatedTickCount");function I(f,T,v,p){const a=s.db.getDateFormat(),d=s.db.getAxisFormat();let m;d?m=d:a==="D"?m="%d":m=n.axisFormat??"%Y-%m-%d";let u=qe(k).tickSize(-p+T+n.gridLineStartPadding).tickFormat(Xt(m));const i=/^([1-9]\d*)(millisecond|second|minute|hour|day|week|month)$/.exec(s.db.getTickInterval()||n.tickInterval);if(i!==null){const Y=parseInt(i[1],10);if(isNaN(Y)||Y<=0)ot.warn(`Invalid tick interval value: "${i[1]}". Skipping custom tick interval.`);else{const o=i[2],G=s.db.getWeekday()||n.weekday,c=k.domain(),A=c[0],$=c[1],z=R(A,$,Y,o);if(z>It)ot.warn(`The tick interval "${Y}${o}" would generate ${z} ticks, which exceeds the maximum allowed (${It}). This may indicate an invalid date or time range. Skipping custom tick interval.`);else switch(o){case"millisecond":u.ticks(Jt.every(Y));break;case"second":u.ticks(Kt.every(Y));break;case"minute":u.ticks(Qt.every(Y));break;case"hour":u.ticks(Zt.every(Y));break;case"day":u.ticks(Ut.every(Y));break;case"week":u.ticks(re[G].every(Y));break;case"month":u.ticks(qt.every(Y));break}}}if(N.append("g").attr("class","grid").attr("transform","translate("+f+", "+(p-50)+")").call(u).selectAll("text").style("text-anchor","middle").attr("fill","#000").attr("stroke","none").attr("font-size",10).attr("dy","1em"),s.db.topAxisEnabled()||n.topAxis){let Y=Xe(k).tickSize(-p+T+n.gridLineStartPadding).tickFormat(Xt(m));if(i!==null){const o=parseInt(i[1],10);if(isNaN(o)||o<=0)ot.warn(`Invalid tick interval value: "${i[1]}". Skipping custom tick interval.`);else{const G=i[2],c=s.db.getWeekday()||n.weekday,A=k.domain(),$=A[0],z=A[1];if(R($,z,o,G)<=It)switch(G){case"millisecond":Y.ticks(Jt.every(o));break;case"second":Y.ticks(Kt.every(o));break;case"minute":Y.ticks(Qt.every(o));break;case"hour":Y.ticks(Zt.every(o));break;case"day":Y.ticks(Ut.every(o));break;case"week":Y.ticks(re[c].every(o));break;case"month":Y.ticks(qt.every(o));break}}}N.append("g").attr("class","grid").attr("transform","translate("+f+", "+T+")").call(Y).selectAll("text").style("text-anchor","middle").attr("fill","#000").attr("stroke","none").attr("font-size",10)}}l(I,"makeGrid");function x(f,T){let v=0;const p=Object.keys(D).map(a=>[a,D[a]]);N.append("g").selectAll("text").data(p).enter().append(function(a){const d=a[0].split(De.lineBreakRegex),m=-(d.length-1)/2,u=C.createElementNS("http://www.w3.org/2000/svg","text");u.setAttribute("dy",m+"em");for(const[S,i]of d.entries()){const Y=C.createElementNS("http://www.w3.org/2000/svg","tspan");Y.setAttribute("alignment-baseline","central"),Y.setAttribute("x","10"),S>0&&Y.setAttribute("dy","1em"),Y.textContent=i,u.appendChild(Y)}return u}).attr("x",10).attr("y",function(a,d){if(d>0)for(let m=0;m<d;m++)return v+=p[d-1][1],a[1]*f/2+v*f+T;else return a[1]*f/2+T}).attr("font-size",n.sectionFontSize).attr("class",function(a){for(const[d,m]of _.entries())if(a[0]===m)return"sectionTitle sectionTitle"+d%n.numberSectionStyles;return"sectionTitle"})}l(x,"vertLabels");function h(f,T,v,p){const a=s.db.getTodayMarker();if(a==="off")return;const d=N.append("g").attr("class","today"),m=new Date,u=d.append("line");u.attr("x1",k(m)+f).attr("x2",k(m)+f).attr("y1",n.titleTopMargin).attr("y2",p-n.titleTopMargin).attr("class","today"),a!==""&&u.attr("style",a.replace(/,/g,";"))}l(h,"drawToday");function E(f){const T={},v=[];for(let p=0,a=f.length;p<a;++p)Object.prototype.hasOwnProperty.call(T,f[p])||(T[f[p]]=!0,v.push(f[p]));return v}l(E,"checkUnique")},"draw"),Bs={setConf:Rs,draw:Hs},Gs=l(t=>`
  .mermaid-main-font {
        font-family: ${t.fontFamily};
  }

  .exclude-range {
    fill: ${t.excludeBkgColor};
  }

  .section {
    stroke: none;
    opacity: 0.2;
  }

  .section0 {
    fill: ${t.sectionBkgColor};
  }

  .section2 {
    fill: ${t.sectionBkgColor2};
  }

  .section1,
  .section3 {
    fill: ${t.altSectionBkgColor};
    opacity: 0.2;
  }

  .sectionTitle0 {
    fill: ${t.titleColor};
  }

  .sectionTitle1 {
    fill: ${t.titleColor};
  }

  .sectionTitle2 {
    fill: ${t.titleColor};
  }

  .sectionTitle3 {
    fill: ${t.titleColor};
  }

  .sectionTitle {
    text-anchor: start;
    font-family: ${t.fontFamily};
  }


  /* Grid and axis */

  .grid .tick {
    stroke: ${t.gridColor};
    opacity: 0.8;
    shape-rendering: crispEdges;
  }

  .grid .tick text {
    font-family: ${t.fontFamily};
    fill: ${t.textColor};
  }

  .grid path {
    stroke-width: 0;
  }


  /* Today line */

  .today {
    fill: none;
    stroke: ${t.todayLineColor};
    stroke-width: 2px;
  }


  /* Task styling */

  /* Default task */

  .task {
    stroke-width: 2;
  }

  .taskText {
    text-anchor: middle;
    font-family: ${t.fontFamily};
  }

  .taskTextOutsideRight {
    fill: ${t.taskTextDarkColor};
    text-anchor: start;
    font-family: ${t.fontFamily};
  }

  .taskTextOutsideLeft {
    fill: ${t.taskTextDarkColor};
    text-anchor: end;
  }


  /* Special case clickable */

  .task.clickable {
    cursor: pointer;
  }

  .taskText.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }

  .taskTextOutsideLeft.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }

  .taskTextOutsideRight.clickable {
    cursor: pointer;
    fill: ${t.taskTextClickableColor} !important;
    font-weight: bold;
  }


  /* Specific task settings for the sections*/

  .taskText0,
  .taskText1,
  .taskText2,
  .taskText3 {
    fill: ${t.taskTextColor};
  }

  .task0,
  .task1,
  .task2,
  .task3 {
    fill: ${t.taskBkgColor};
    stroke: ${t.taskBorderColor};
  }

  .taskTextOutside0,
  .taskTextOutside2
  {
    fill: ${t.taskTextOutsideColor};
  }

  .taskTextOutside1,
  .taskTextOutside3 {
    fill: ${t.taskTextOutsideColor};
  }


  /* Active task */

  .active0,
  .active1,
  .active2,
  .active3 {
    fill: ${t.activeTaskBkgColor};
    stroke: ${t.activeTaskBorderColor};
  }

  .activeText0,
  .activeText1,
  .activeText2,
  .activeText3 {
    fill: ${t.taskTextDarkColor} !important;
  }


  /* Completed task */

  .done0,
  .done1,
  .done2,
  .done3 {
    stroke: ${t.doneTaskBorderColor};
    fill: ${t.doneTaskBkgColor};
    stroke-width: 2;
  }

  .doneText0,
  .doneText1,
  .doneText2,
  .doneText3 {
    fill: ${t.taskTextDarkColor} !important;
  }

  /* Done task text displayed outside the bar sits against the diagram background,
     not against the done-task bar, so it must use the outside/contrast color. */
  .doneText0.taskTextOutsideLeft,
  .doneText0.taskTextOutsideRight,
  .doneText1.taskTextOutsideLeft,
  .doneText1.taskTextOutsideRight,
  .doneText2.taskTextOutsideLeft,
  .doneText2.taskTextOutsideRight,
  .doneText3.taskTextOutsideLeft,
  .doneText3.taskTextOutsideRight {
    fill: ${t.taskTextOutsideColor} !important;
  }


  /* Tasks on the critical line */

  .crit0,
  .crit1,
  .crit2,
  .crit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.critBkgColor};
    stroke-width: 2;
  }

  .activeCrit0,
  .activeCrit1,
  .activeCrit2,
  .activeCrit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.activeTaskBkgColor};
    stroke-width: 2;
  }

  .doneCrit0,
  .doneCrit1,
  .doneCrit2,
  .doneCrit3 {
    stroke: ${t.critBorderColor};
    fill: ${t.doneTaskBkgColor};
    stroke-width: 2;
    cursor: pointer;
    shape-rendering: crispEdges;
  }

  .milestone {
    transform: rotate(45deg) scale(0.8,0.8);
  }

  .milestoneText {
    font-style: italic;
  }
  .doneCritText0,
  .doneCritText1,
  .doneCritText2,
  .doneCritText3 {
    fill: ${t.taskTextDarkColor} !important;
  }

  /* Done-crit task text outside the bar — same reasoning as doneText above. */
  .doneCritText0.taskTextOutsideLeft,
  .doneCritText0.taskTextOutsideRight,
  .doneCritText1.taskTextOutsideLeft,
  .doneCritText1.taskTextOutsideRight,
  .doneCritText2.taskTextOutsideLeft,
  .doneCritText2.taskTextOutsideRight,
  .doneCritText3.taskTextOutsideLeft,
  .doneCritText3.taskTextOutsideRight {
    fill: ${t.taskTextOutsideColor} !important;
  }

  .vert {
    stroke: ${t.vertLineColor};
  }

  .vertText {
    font-size: 15px;
    text-anchor: middle;
    fill: ${t.vertLineColor} !important;
  }

  .activeCritText0,
  .activeCritText1,
  .activeCritText2,
  .activeCritText3 {
    fill: ${t.taskTextDarkColor} !important;
  }

  .titleText {
    text-anchor: middle;
    font-size: 18px;
    fill: ${t.titleColor||t.textColor};
    font-family: ${t.fontFamily};
  }
`,"getStyles"),js=Gs,Qs={parser:rs,db:zs,renderer:Bs,styles:js};export{Qs as diagram};
