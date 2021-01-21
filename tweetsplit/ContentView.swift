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
    @Published var filename : String = "tweet.storm"
    @Published var numberFirst : Bool = false

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
            tweet.ord = genOrd(ord,tweets.count)
            
            if (!numberFirst) {
                tweet.text = tweet.text + " " + tweet.ord
            } else {
                tweet.text = tweet.ord + " " + tweet.text
            }
            ord += 1
        }
    }

    func genOrd(_ ord: Int, _ total: Int) -> String
    {
        return "(\(ord+1)/\(tweets.count))"
    }
    
    //one, two, three, four, five, six, seven, eight, nine, ten.
    
    func length(_ tweet : String) -> Int {
        let len = tweet.count
        let split = tweet.split(separator: "\n")
        var sub = 0

        for word in split {
            if (word.hasPrefix("http"))
            {
                sub += word.count - 16
                print("sub http \(sub)")
            }
        }
        return len - sub
    }
    
    func split() {


        let   max = 270

        var tweet  = Tweet()
        var len    = 0
        let words  = text.split(separator: "\n", maxSplits: 9999, omittingEmptySubsequences: false)
  
        tweets = []
        
        for word in words {

            var wordLen = word.count
            print("processing [\(word)]")
            
            if word.hasPrefix("http")
            {
                print("http")
                wordLen = 16
            }

            if len + wordLen + 1 >= max || word == "___"
            {
                if (tweet.text.last == "\n") {
                    tweet.text.removeLast()
                }
                addTweet(tweet)
                tweet = Tweet()
                len = 0
            }

            if (word != "___") {
                tweet.text.append(contentsOf: word)
                tweet.text.append("\n")
                len += wordLen + 1
            }

        }
        // final words
        addTweet(tweet)
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
        changed   = false
    }
    
    var queued   : Bool = false
    
    var changed  : Bool
    {
        didSet {
            if (changed && !queued) {
                let seconds = 0.05
                queued = true
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    self.save()
                    self.split()
                    self.renumber()
                    self.queued = false
                }
            }
        }
    }

    func save()
    {
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")

        do {
            try text.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            print("error writing to file")
        }

        print("saved \(filename)")
        changed = false
    }

    func addTweet(_ tweet: Tweet) {
        tweets.append(tweet)
        tweet.count = length(tweet.text)
    }

    func addTweet() {
        addTweet(text: "")
    }
    
    func addTweet(text: String) {
        
        let tweet = Tweet()
        tweet.text  = text
        tweet.count = length(tweet.text)
        tweets.append(tweet)
    }

    init() {
        changed  = false
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
                    .frame(maxWidth: 55)

                Text("\(tweet.count)")
                    .foregroundColor(.red)
                    .padding(.trailing)
                    .frame(maxWidth: 55)
            }.frame(width: 55)
            
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
                    tweets.changed   = false // don't save during name changes
                })

            if (tweets.needsLoad) {
                Button(action: tweets.load)
                {
                    Text("Load")
                }
            }
            
            Button(action: tweets.save)
            {
                Text("Save")
            }
            
            Toggle(isOn: $tweets.numberFirst) {
                Text("Number First")
            }
            .onChange(of: tweets.numberFirst, perform: { value in
                tweets.split()
                tweets.renumber()
            })
        }

        VStack
        {
            HStack {
                TextEditor(text: $tweets.text)
                    .onChange(of: tweets.text, perform: { value in
                        tweets.changed   = true
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
