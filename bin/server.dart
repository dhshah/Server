// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client program is note_client.dart.
// Use note_taker.html to run the client.

import 'dart:io';
import 'dart:convert' show JSON;
import 'dart:collection';
import 'dart:math' show Random;

HashMap<String,List<Quote>> quotes = new HashMap();

class Quote{
  String author;
  String genre;
  String quote;
  
  Quote(this.genre, this.author, this.quote);
  
  String toString() => "Author: ${author}; Quote: ${quote} ";
}

void main() {
  List<String> lines = new File('quotes.json.txt').readAsLinesSync();
  
  String current;
  for (int a = 0; a < lines.length; a++){
    if (lines[a].startsWith("Genre: ")){
      current = lines[a].substring(7);
      if (!quotes.keys.contains(lines[a].substring(7)))
          quotes[lines[a].substring(7)] = new List<Quote>();
    } else if (lines[a].startsWith("Author: ")){
      quotes[current].add(new Quote(current, lines[a].substring(8), lines[a+1].substring(7)));
      a++;
    }
  }
  /*
  String str;
  for (int a = 0; a < quotes.length; a++){
    str = quotes.keys.toList()[a];
    print (str + "---");
    for (int b = 0; b < quotes[str].length; b++){
      print(quotes[str][b].toString());
    }
  }*/
  print ("Listening");
  
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4042)
      .then(listenForRequests)
      .catchError((e) => print('hello: ${e.toString()}'));
}

listenForRequests(_server) {
  _server.listen((HttpRequest request) {
    switch (request.method) {
      case 'POST':
        handleGetQuote(request);
        break;
      default:
        defaultHandler(request);
        break;
    }
  },
  onDone: () => print('No more requests.'),
  onError: (e ) => print(e.toString()));
}

void handleGetQuote (HttpRequest request){
  StringBuffer data = new StringBuffer();

    addCorsHeaders(request.response);
    request.listen((buffer) {
      data.write(new String.fromCharCodes(buffer));
    }, onDone: () {
      var decoded = JSON.decode(data.toString());
      getQuote(request, decoded["getQuote"]);
    }, onError: (_) {
      print('Request listen error.');
    });
}

void getQuote(HttpRequest request, String s){
  request.response.statusCode = HttpStatus.OK;
  
  Random r = new Random();
  String str;
  
  if (quotes.keys.contains(s))
    str = quotes[s][r.nextInt(200000) % quotes[s].length].toString();
  else {
    String st = quotes.keys.toList()[r.nextInt(quotes.keys.length)];
    str = quotes[st][r.nextInt(quotes[st].length)].toString();
  }
  print(str);
  request.response.writeln(str);
  request.response.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.write('Not found: ${req.method}, ${req.uri.path}');
  res.close();
}

void handleOptions(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print('${req.method}: ${req.uri.path}');
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void addCorsHeaders(HttpResponse res) {
  res.headers.add('Access-Control-Allow-Origin', '*');
  res.headers.add('Access-Control-Allow-Methods', 'POST');
  res.headers.add('Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept');
}
