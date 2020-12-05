//
//  ContentView.swift
//  tweetsplit
//
//  Created by Avi Bar-Zeev on 12/3/20.
//

import SwiftUI

let separator : Character = "/"

class Tweet : Identifiable, ObservableObject
{
    static func == (lhs: Tweet, rhs: Tweet) -> Bool {
        return lhs.id == rhs.id
    }
    
    @Published var text  : String = ""
    @Published var ord   : String = ""
    @Published var count : Int = 0

}

class Tweets : ObservableObject
{
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
    
    func denumber() {

        var ord = 0 // don't prune zero
        while ord < tweets.count
        {
            let tweet = tweets[ord]
            var ch = tweet.text.last
            
            while (tweet.text.count > 0 && ch != nil && (ch!.isWhitespace || ch!.isNumber || ch!.isNewline || ch!=="/")) {
                tweet.text.removeLast()
                ch = tweet.text.last!
            }

            ord += 1
        }
    }
    
    func flow() {
        
        var ord = 0
        
        denumber()
        
        while ord < tweets.count {
            
            let tweet = tweets[ord]
            tweet.ord = " \(ord+1)/\(tweets.count)"
            let   max = 280 - tweet.ord.count

            print("\(tweet.text) len=\(tweet.text.count)")
            
            if tweet.text.count >= max
            {
                if (ord >= tweets.count - 1) {
                    print("adding tweet")
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
 
        prune()
        renumber()
        
        needsSave = true
    }

    func load()
    {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")
        
        print("FilePath: \(fileURL.path)")

        do {
            var data = try String(contentsOfFile: fileURL.path, encoding: .utf8)

            tweets = []
            var tweet : String = ""
            var pattern = 0
            
            while (data.count > 0)
            {
                let ch = data.removeFirst()
                tweet.append(ch)

                if (ch.isNumber || ch.isNewline || ch=="/")  { pattern += 1 }
                else { pattern = 0 }

                print("char \(ch) pattern \(pattern)")
                
                if (ch.isNewline && pattern > 3) {

                    if (ch.isNewline) { tweet.removeLast() }

                    print("added tweet \(tweet)")
                    addTweet(text: tweet)
                    tweet = ""
                }
            }

            if (tweet.count > 0) {
                print("added remainder \(tweet)")
                addTweet(text: tweet)
            }
            
        }
        catch {
            print("error loading file")
        }
        
        print("loaded \(filename)")

        denumber()
        flow()
        prune()

        needsLoad = false
        needsSave = false
    }
    
    func save()
    {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")

        print("FilePath: \(fileURL.path)")

        var data = ""
        for tweet in tweets {
            data.append(tweet.text + "\n")
        }
        
        do {
            try data.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            print("error writing to file")
        }

        print("saved \(filename)")
        
        needsSave = false
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
        tweets.append(Tweet())
        tweets.append(Tweet())
        flow()
    }
}

struct TweetView: View {
    @ObservedObject var tweet  : Tweet
    @ObservedObject var tweets : Tweets

    var body: some View {
        HStack {
            Text("\(tweet.count)")
                .foregroundColor(.red)
                .padding(.trailing)
                .frame(maxWidth: 50)

            TextEditor(text: $tweet.text)
                .onChange(of: tweet.text, perform: { value in
                    tweet.count      = value.count
                    tweets.needsSave = true
                })
                .padding(1)
                .border(Color.red, width: 1)
                .frame(minHeight: 20)

            Text("\(tweet.ord)")
                .foregroundColor(.white)
                .padding(.trailing)
                .frame(maxWidth: 50)
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
        
        ScrollView(.vertical, showsIndicators: true)
        {
            ForEach(tweets.tweets) { tweet in
                TweetView(tweet: tweet, tweets: tweets)
            }
        }
        HStack {
            Button(action: tweets.addTweet)
            {
                Text("Tweet ")
            }
            Button(action: tweets.flow)
            {
                Text("Reflow")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tweets: tweets)
    }
}
