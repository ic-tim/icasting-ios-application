//
//  EndpointFactory.swift
//  iCasting
//
//  Created by T. van Steenoven on 08-04-15.
//  Copyright (c) 2015 T. van Steenoven. All rights reserved.
//

import Foundation



// The URL consists of certain parts: the total url could be: 
// [http://] + [api.demo.com] + [/version1] + [/resource/(insert)/detail/(insert)] + [?param1="val"+param2="val"]
private struct URLBuilder {
    let scheme : String = "https"
    var host : String?
    var version : String?
    var uri : EndpointProtocol?
    var insert : [String]?
    var params : [String:String]?
}

class URLSimpleFactory {
    
    class func createURL(uri: EndpointProtocol, insert:[String]?, params:paramsType) -> NSURL {

        var builder: URLBuilder
        
        // A URL to load media, like images, has another host, determine which host.
        if let _uri = uri as? APIMedia {

            builder = URLBuilder(host: Host.Media, version: nil, uri: uri, insert: insert, params: params)
        }
        else {
            builder = URLBuilder(host: Host.API, version: "/api/v\(Host.APIVersion)", uri: uri, insert: insert, params: params)
        }
        
        return URLResolver(builder: builder).nsurl
    }
}

private class URLResolver {
    
    var nsurl : NSURL = NSURL()
    
    init(builder: URLBuilder) {
        
        func endpointNSURL() -> NSURL {

            // Start the resolving proces and creation of an NSURL
            var resolved : NSString = ""
            
            if let _version = builder.version {
                resolved = _version
            }
            
            
            // Check if the insert array contains variable url parts to insert into URI endpoint
            func insertFragments() -> NSString {
                var sUri:String
                if let insert = builder.insert {
                    println("Will insert fragments into url")
                    sUri = ApiURL(uri: builder.uri!, insert: insert).resolve()
                } else {
                    sUri = builder.uri!.endpoint()
                }
                resolved = "\(resolved)/\(sUri)"
                return resolved
            }

            // Add the query string to the path
            func queryString() -> NSString {

                if let params = builder.params {
                    
                    resolved = "\(resolved)?"
                    for (key, val) in params {
                        resolved = "\(resolved)\(key)=\(val)&"
                    }
                    // Remove the last & char from the query string
                    resolved = resolved.substringToIndex(resolved.length-1)
                }
                return resolved
            }
            
            resolved = insertFragments()
            resolved = queryString()
            
            let url : NSURL = NSURL(
                scheme: builder.scheme,
                host: builder.host,
                path: resolved as String)!
            
            return url
        }

        self.nsurl = endpointNSURL()
        println("Resolved URL: \(self.nsurl)")
    }
    
 }
