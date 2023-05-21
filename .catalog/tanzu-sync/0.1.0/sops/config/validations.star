load("@ytt:struct", "struct")

def _well_formed_age_key(value):
  return value.strip().find("AGE-SECRET-KEY-") >= 0
end

def _age_key_validation():
  return ("well-formed Age Identity/Key (i.e. contains \"AGE-SECRET-KEY-\")", lambda value: _well_formed_age_key(value))
end

valid=struct.make(age_key=_age_key_validation)

