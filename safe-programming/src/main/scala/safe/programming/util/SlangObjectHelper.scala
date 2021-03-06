package safe.programming
package util

import safe.safelog._

/**
 * Provide wrappers for slang objects
 */

trait SlangObjectHelper {
  val emptyEnvs = ":::"
 
  def buildConstant(id: String): Constant = {
    Constant(StrLit(id), StrLit("nil"), StrLit("StrLit"), Encoding.AttrBase64)
  }

  def firstTokenOfInferredResult(inferenceRes: Seq[Seq[Statement]]): String = {
    //println(s"[SlangObjectWrappers] inferenceRes: ${inferenceRes}")
    val allstmts: Seq[Statement] = inferenceRes.flatten 
    if(allstmts.isEmpty) { throw UnSafeException("Empty inference results") } 
    val firstStmt = allstmts.head
    if(firstStmt.terms.isEmpty) { throw UnSafeException("Empty statement: ${firstStmt}") }
    val firstToken = firstStmt.terms.head.id.name
    firstToken
  }
}
