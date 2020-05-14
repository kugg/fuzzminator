import cpp
from MacroInvocation i
where i.getMacroName().matches("BOUNDED_EQUAL_NO_CASE")
select i.toString(), i.getLocation(), i.getAnExpandedElement()
