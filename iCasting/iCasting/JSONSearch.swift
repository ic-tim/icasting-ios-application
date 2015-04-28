//
//  JSONSearch.swift
//  iCasting
//
//  Created by Tim van Steenoven on 24/04/15.
//  Copyright (c) 2015 T. van Steenoven. All rights reserved.
//

import Foundation

typealias FieldPath = [String]

class GenericSearch {
    
    private func search(source: NSDictionary, fields: FieldPath) -> AnyObject? {
        
        var s: AnyObject = source
        
        for field in fields {
            
            if let next: AnyObject = s.objectForKey(field) {
                s = next
            }
            else {
                return nil
            }
        }
        return s
    }
}

class Search: GenericSearch {
    
     func search(source: NSDictionary, fields: FieldPath) -> String? {
        
        if let obj: AnyObject = super.search(source, fields: fields) {
            
            if obj is String {
                return obj as? String
            }
            return "Not a String"
        }
        return "-"
    }
    
    func search(source: NSDictionary, fields: FieldPath) -> NSArray? {
        
        if let obj: AnyObject = super.search(source, fields: fields) {
            
            if obj is NSArray {
                return obj as? NSArray
            }
            return ["Not an array"]
        }
        return nil
    }
    
    func search(source: NSDictionary, fields: FieldPath) -> NSDictionary? {
        
        if let obj: AnyObject = super.search(source, fields: fields) {
            
            if obj is NSDictionary {
                return obj as? NSDictionary
            }
            return ["error":"is not an dictionary"]
        }
        return nil
    }
}


//func parseBlog(blog: AnyObject) -> MatchData? {
//    
//    let mkBlog = curry { id, name, needsPassword, url in
//        Blog(id: id, name: name, needsPassword: needsPassword, url: url)
//    }
//    
//    return asDict(blog) >>>= {
//        mkBlog <*> int($0,"id")
//            <*> string($0,"name")
//            <*> bool($0,"needspassword")
//            <*> (string($0, "url") >>>= toURL)
//    }
//}


//func parseJSON() {
//    
//    
//    let blogs = dictionary(parsedJSON, "blogs") >>>= {
//        array($0, "blog") >>>= {
//            join($0.map(parseBlog))
//        }
//    }
//    
//    println("posts: \(blogs)")
//}



class JSONSearchFacade {
    private static let JSONSearch: Search = Search()
    
    class func stringSearch(#source: NSDictionary, fields: Fields) -> String? {
        return JSONSearch.search(source, fields: fields.getPath().path)
    }
    class func arraySearch(#source: NSDictionary, fields: Fields) -> NSArray? {
        return JSONSearch.search(source, fields: fields.getPath().path)
    }
    class func dictionarySearch(#source: NSDictionary, fields: Fields) -> NSDictionary? {
        return JSONSearch.search(source, fields: fields.getPath().path)
    }
    
    class func search(#source: NSDictionary, fields: Fields) -> NSDictionary {
        
        return NSDictionary()
        

    }
    

    
}




