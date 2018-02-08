//
//  MyLog.swift
//  FoodTracker
//
//  Created by Yuhei Kikuchi on 2018/01/31.
//

import Foundation

/*
 Usage:
 class Hoge {
   func hoge() {
     MyLog.traceFunc()
   }
 }

 Limitation:
 This dumps filename instead of actual class name so not accurate in a meaning.

 TODO: Should decide which output func to use.
 - print      : normal output.
 - debugPrint : almost same as "print" but outputs are surrounded by "".
 - NSLog      : almost same as "print" but timestamp will be displayed.
 */
class LogUtil {
    static let SWIFT_FILENAME_SUFFIX = ".swift"

    // MARK: Public

    static func traceFunc(className      file       : String                  = #file,
                          sourceLineNum  line       : Int                     = #line,
                          sourceFuncName funcName   : String                  = #function,
                          params         funcParams : Dictionary<String, Any> = Dictionary(),
                          message        msg        : String?                 = nil) {

        let prefix = getPrefix(file, line)
        NSLog(prefix + "\(funcName)")

        if (funcParams.isEmpty) {
            return
        }

        for (key, value) in funcParams {
            NSLog(prefix + "  >> \(key) : \(value)")
        }

        if let _ = msg {
            NSLog(prefix + " >> \(msg!)")
        }
    }

    /*
    static func traceFunc(_              message    : String,
                          sourceFilePath file       : String                  = #file,
                          sourceLineNum  line       : Int                     = #line,
                          sourceFuncName funcName   : String                  = #function) {
        print("message  : \(message)")
        print("file     : \(file)")
        print("line     : \(line)")
        print("funcName : \(funcName)")

        let prefix = getPrefix(file, line)
        NSLog(prefix + "\(funcName) \(message)" )
    }
 */

    static func debug(sourceFilePath file : String = #file,
                      sourceLineNum  line : Int    = #line,
                      _ message           : String) {
        let prefix = getPrefix(file, line)
        NSLog(prefix + "=> \(message)")
    }

    static func error(sourceFilePath file : String = #file,
                      sourceLineNum  line : Int    = #line,
                      _ error             : Error) {
        let prefix = getPrefix(file, line)
        NSLog(prefix + "=> \(error)")
    }

    // MARK: Private

    static private func getPrefix(_ filePath : String,
                                  _ lineNum  : Int) -> String {
        let fileBaseName =
            URL(fileURLWithPath: filePath)
                .lastPathComponent
                .replacingOccurrences(of: SWIFT_FILENAME_SUFFIX, with: "")

        return "[\(fileBaseName) <line: \(String(format: "%3d", lineNum))>] "
    }

    static func calcSpace(_ target: String) -> String {
        var space = ""
        for _ in 0..<target.count {
            space += " " // increment white space
        }
        return space
    }
}


/*
 Usage:
 class Hoge: MyLogProtocol {
   func hoge() {
     traceFunc()
   }
 }

 Limitation:
 This dumps actual class name though, need to declare implementation on class definition.
 */
protocol LogUtilProtocol {
    func traceFunc(sourceFunctName: String,
                   sourceLineNum: Int) -> Void
}

extension LogUtilProtocol {
    func traceFunc(sourceFunctName: String = #function,
                   sourceLineNum:   Int    = #line) {
        debugPrint("\(String(describing: type(of:self)))(\(sourceLineNum))::\(sourceFunctName)")
    }
}
