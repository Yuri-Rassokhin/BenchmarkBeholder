
class Projects

def codes
    return `mysql -N -B -e "select code from bbh.projects;"`.split("\n").join.tr("\"",'')
end

def projects
  warning("this yet to be implemented")
end

end

