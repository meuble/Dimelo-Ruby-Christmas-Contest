#!/usr/bin/env ruby

require 'hashie'

# Constant given by default to be the sample profile to study
PROFILE = {
  "login" => "defunkt",
  "followers" => 4674,
  "commits" => 8901,
  "repositories" => [
    {
      "watchers" => 79,
      "forks" => 9,
      "name" => "choice"
    },
    {
      "watchers" => 28,
      "forks" => 1,
      "name" => "mapreducerb"
    },
    {
      "watchers" => 16,
      "forks" => 3,
      "name" => "ambitious_activerecord"
    },
    {
      "watchers" => 151,
      "forks" => 39,
      "name" => "emacs"
    },
    {
      "watchers" => 787,
      "forks" => 116,
      "name" => "github-gem"
    },
    {
      "watchers" => 1559,
      "forks" => 298,
      "name" => "facebox"
    },
    {
      "watchers" => 2977,
      "forks" => 425,
      "name" => "resque"
    } 
  ]
}

# Class that will parse and compute rules for a given profile and rules set
class RulesParser
  attr_accessor :profile, :commit, :repository, :follower
  
  def initialize(profile, file_name)
    self.parse(file_name)
    self.profile = profile
  end
  
  def parse(file_name)
    File.open(file_name) do |file|
      file.each do |line|
        parse_line(line)
      end
    end
  end
  
  # the score is the addition of the score from commits, followers ad repositories
  def compute!
    compute_commits + compute_followers + compute_repositories
  end
  
private
  # To find points to apply to a target, we iterate on each rules of the set and evaluate it.
  # This will return nil or a value.
  #  - we do nothing if nil (the condition hasn't succeded, no points to give)
  #  - we replace the value if something and accumulator is false
  #  - we add the value if something and accumulator is true
  def find_points(field, data = nil)
    points = 0
    self[field].each do |accumulator, commande|
      value = commande.call(data)
      next if value.nil?
      points = accumulator ? points + value : value
    end
    points
  end

  def compute_commits
    return 0 if self.commit.nil? || self.commit.empty?
    self.profile['commits'] * find_points(:commit)
  end
  
  # For repositories, the set of rules apply to each repository. So we iterate on them and apply the rules
  def compute_repositories
    return 0 if self.repository.nil? || self.repository.empty?
    self.profile['repositories'].inject(0) do |acc, repo|
      acc += find_points(:repository, repo)
    end
  end

  def compute_followers
    return 0 if self.follower.nil? || self.follower.empty?
    self.profile['followers'] * find_points(:follower)
  end

  # For each rule, we find the target, the assignment operand and the commande
  # since the commande is written in a DSL similar to ruby, I think we can use a creepy `eval` pretty safely.
  def parse_line(line)
    target, operator, *commande = line.split(' ')
    self[target] = [] if self[target].nil?
    self[target] << [operator == '+=', Proc.new {|repository| eval(commande.join(' ')) }]
  end
  
  # Utilities methods to access attributes easily
  def [](field)
    self.send(field)
  end

  # Utilities methods to assign attributes easily
  def []=(field, value)
    self.send("#{field}=", value)
  end
end

# Get the rules file name
rules_file_name = ARGV.first

if rules_file_name
  # If we have rules, parse the file and compute score
  p RulesParser.new(Hashie::Mash.new(PROFILE), rules_file_name).compute!
end