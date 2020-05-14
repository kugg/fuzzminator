import cpp
import semmle.code.cpp.dataflow.DataFlow
class StringTaint extends DataFlow::Configuration {
  StringTaint() { this = "StringTaint" }

  override predicate isSource(DataFlow::Node source) {
    source.asExpr() instanceof StringLiteral
  }

  override predicate isSink(DataFlow::Node sink) {
    exists (FunctionCall fc |
      sink.asExpr() = fc.getAnArgument() and
      (
		fc.getTarget().getQualifiedName().toLowerCase().matches("%str%") or
		fc.getTarget().getQualifiedName().toLowerCase().matches("%cmp%") or
		fc.getTarget().getQualifiedName().toLowerCase().matches("%header%") or
		fc.getTarget().getQualifiedName().toLowerCase().matches("%parse_content_disposition%")
		
		)
   ) or
     exists (MacroInvocation i | (
		 i.getMacroName().toLowerCase().matches("%equal%") or
		 i.getMacroName().toLowerCase().matches("%cmp%") or
		 i.getMacroName().toLowerCase().matches("%str%") or
		 i.getMacroName().toLowerCase().matches("%starts%")
		 )
		 and (
		  sink.asExpr() = i.getExpr() or
		  sink.asExpr() = i.getExpr().getAChild() or
		  sink.asExpr() = i.getAnExpandedElement()
		  )
      )
  }
}

from StringLiteral srcStr, Expr strcmp, StringTaint config
where config.hasFlow(DataFlow::exprNode(srcStr), DataFlow::exprNode(strcmp))
select srcStr.toString(), strcmp.getLocation()
