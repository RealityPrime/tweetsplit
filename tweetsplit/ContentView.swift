//
//  ContentView.swift
//  tweetsplit
//
//  Created by Avi Bar-Zeev on 12/3/20.
//

import SwiftUI
import AppKit

let separator : Character = "/"

class Tweet : Identifiable, ObservableObject
{
    static func == (lhs: Tweet, rhs: Tweet) -> Bool {
        return lhs.id == rhs.id
    }
    
    @Published var text  : String = ""
    @Published var ord   : String = ""
    @Published var count : Int = 0
    @Published var selected : Bool = false

}

class Tweets : ObservableObject
{
    @Published var text     : String = ""
    @Published var tweets   : [Tweet] = []
    @Published var needsLoad: Bool = true
    @Published var needsSave: Bool = false
    @Published var filename : String = "tweet.storm"

    func prune() {
        var i = 0
        
        while i < tweets.count
        {
            let tweet = tweets[i]
            if (i > 0 && tweet.text == "") {
                print("removing empty tweet \(i)")
                tweets.remove(at: i)
            }
            else {
                i += 1
            }
        }
    }

    func renumber() {
        var ord = 0 // don't prune zero
        while ord < tweets.count
        {
            let tweet = tweets[ord]
            tweet.ord = "\(ord+1)/\(tweets.count)"
            
            tweet.text.append(" " + tweet.ord)
            
            ord += 1
        }
    }

    //one, two, three, four, five, six, seven, eight, nine, ten.
    
    func flow() {
        
        var ord = 0
        
        while ord < tweets.count {
            
            let tweet = tweets[ord]
            tweet.ord = " \(ord+1)/\(tweets.count)"
            let   max = 280 - tweet.ord.count
            
            if tweet.text.count >= max
            {
                if (ord >= tweets.count - 1) {
                    print("flow last tweet")
                    addTweet()
                }

                let next = tweets[ord+1]
                var ch : Character = "@"
                
                while (tweet.text.count >= max || ch != " ")
                {
                    ch = tweet.text.removeLast()
                    next.text.insert(ch, at: next.text.startIndex)
                }
                
                tweet.count = tweet.text.count
                next.count = next.text.count

            }

            ord += 1
        }
 
        needsSave = true
    }

    func split() {

        var pattern = 0
        var data    = text

        tweets = []
        var tweet = Tweet()
        var next  = Tweet()
        let   max = 274
        
        while (data.count > 0)
        {
            var ch = data.removeFirst()
             
            if (ch.isNewline && pattern >= 3) {
//                tweet.text.removeLast()
                print("split \(tweet.text)")
                addTweet(tweet)
                tweet = next
                next  = Tweet()
                pattern = 0
            }
            else if (ch == "_")
            {
                pattern += 1
            }
            else {
                pattern = 0
                tweet.text.append(ch)
            }

            if (tweet.text.count >= max) {
                while (tweet.text.count >= max || ch != " ")
                {
                    print("backing up to space \(ch)")
                    ch = tweet.text.removeLast()
                    next.text.insert(ch, at: next.text.startIndex)
                }
                addTweet(tweet)
                tweet = next
                next  = Tweet()
            }
        }

        print("split final \(tweet.text) : \(next.text) ")

        if (tweet.text.count > 0) {
            addTweet(tweet)
        }
        
        if (next.text.count > 0) {
            addTweet(next)
        }
    }
    
    func load()
    {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")
        
        do {
            text = try String(contentsOfFile: fileURL.path, encoding: .utf8)
            split()
            renumber()
        }
        catch {
            print("error loading file")
        }
        
        print("loaded \(filename)")

        needsLoad = false
        needsSave = false
    }
    
    func save()
    {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")

        print("FilePath: \(fileURL.path)")

        do {
            try text.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            print("error writing to file")
        }

        print("saved \(filename)")
        
        needsSave = false
    }

    func addTweet(_ tweet: Tweet) {
        tweets.append(tweet)
        tweet.count = tweet.text.count
    }

    func addTweet() {
        addTweet(text: "")
    }
    
    func addTweet(text: String) {
        
        let tweet = Tweet()
        tweet.text  = text
        tweet.count = text.count
        tweets.append(tweet)
    }

    init() {
        tweets.append(Tweet())
    }
}

struct TweetView: View {
    @ObservedObject var tweet  : Tweet
    @ObservedObject var tweets : Tweets
    
    var body: some View {
        HStack(alignment: .top, spacing: 1)
        {
            VStack {
                Text("\(tweet.ord)")
                    .foregroundColor(.white)
                    .padding(.trailing)
                    .frame(maxWidth: 50)

                Text("\(tweet.count)")
                    .foregroundColor(.red)
                    .padding(.trailing)
                    .frame(maxWidth: 50)
            }.frame(width: 40)
            
            Text(tweet.text)
                .padding(1)
                .frame(width: 400, alignment: .topLeading)
                .border(tweet.selected ? Color.blue : Color.red, width: 1)
                .background(tweet.selected ? Color.white : Color.black)
                .foregroundColor(tweet.selected ? Color.black : Color.white)
                .onTapGesture {
                    for twt in tweets.tweets { twt.selected = false }
                    tweet.selected = true
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    let ret = pb.setString(tweet.text, forType: .string)
                    print("copy \(ret)")

                }
        }
    }
}

struct ContentView: View {

    @ObservedObject var tweets : Tweets
    
    var body: some View {

        HStack {
            TextField("Filename:", text: $tweets.filename)
                .onChange(of: tweets.filename, perform: { value in
                    tweets.needsLoad = true
                })

            if (tweets.needsLoad) {
                Button(action: tweets.load)
                {
                    Text("Load")
                }
            }
            
            if (tweets.needsSave) {
                Button(action: tweets.save)
                {
                    Text("Save")
                }
            }
        }

        VStack
        {
            HStack {
                TextEditor(text: $tweets.text)
                    .onChange(of: tweets.text, perform: { value in
                        tweets.needsSave = true
                        tweets.split()
                        tweets.renumber()
                    })
                    .font(.system(size: 14, weight: .bold, design: .default))

                List {
                    ForEach(tweets.tweets) { tweet in
                        TweetView(tweet: tweet, tweets: tweets)
                    }
                }.frame(width: 500)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tweets: tweets)
    }
}