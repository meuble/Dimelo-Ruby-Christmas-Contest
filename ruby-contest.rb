#!/usr/bin/env ruby

require 'hashie'

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
  
  def compute!
    compute_commits + compute_followers + compute_repositories
  end
  
private
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

  def parse_line(line)
    target, operator, *commande = line.split(' ')
    self[target] = [] if self[target].nil?
    self[target] << [operator == '+=', Proc.new {|repository| eval(commande.join(' ')) }]
  end
  
  def [](field)
    self.send(field)
  end
  
  def []=(field, value)
    self.send("#{field}=", value)
  end
end

rules_file_name = ARGV.first

if rules_file_name
  p RulesParser.new(Hashie::Mash.new(PROFILE), rules_file_name).compute!
end