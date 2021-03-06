# -*- encoding : utf-8 -*-
require "active_support/core_ext/hash"
require 'httparty'
require 'cutara'
module Cutara
  class TarantulaUpdater
    include HTTParty

    @config = nil
    #debug_output $stdout
    headers  'Content-type' => 'application/xml', 'Accept' => 'application/xml' 
    if ENV['http_proxy'] =~ /^http:\/\/(.+):(\d{4})\/?$/
      http_proxy $1, $2
    end

    def self.config= hash
      @config = hash
    end

    def self.get_tests options 
      options = options.merge({ "language" => @config["language"] })
      params = { 
        :basic_auth => { :username => @config["username"], :password => @config["password"] },
        :body => options.to_xml(:skip_types => true, :root => "request")
      }
      response = self.post(@config["server"]+'/api/get_scenarios', params)
      raise "TARANTULA RESPONSE: " + response.body.to_s unless response.code == 200
      response.body.to_s
    end

    def self.update_testcase_step(project, execution, testcase, step_position, result, comment)
      body = {      
          :project => project,
          :execution => execution,
          :testcase => testcase,
          :position => step_position,
          :result => result,
          :comment => comment,
        }.to_xml(:skip_types => true, :root => "request")

      params = { 
        :basic_auth => { :username => @config["username"], :password => @config["password"] },
        :body => body
      }
      response = self.post(@config["server"]+'/api/update_testcase_step', params)
      raise "TARANTULA RESPONSE: " + response.body.to_s unless response.code == 200
      response.body.to_s
    end

    def self.update_testcase_results(project, execution, testcase, duration, result)
      body = {      
          :project => project,
          :execution => execution,
          :testcase => testcase,
          :duration => duration,
          :result => result
        }.to_xml(:skip_types => true, :root => "request")

      params = { 
        :basic_auth => { :username => @config["username"], :password => @config["password"] },
        :body => body
      }
      response = self.post(@config["server"]+'/api/update_testcase_results', params)
      raise "TARANTULA RESPONSE: " + response.body.to_s unless response.code == 200
      response.body.to_s
    end
  end
end
