# -*- encoding : utf-8 -*-
require 'cucumber/formatter/html'
require 'TarantulaUpdater'
require 'cutara'

module Cucumber
  module Formatter
    module Duration
      def format_duration_simple(seconds)
        seconds
      end
    end
    class CustomTarantulaHtmlFormatter < Html

      def initialize(runtime, path_or_io, options)
        @io = ensure_io(path_or_io, "html")
        @runtime = runtime
        @options = options
        @buffer = {}
        @builder = create_builder(@io)
        @feature_number = 0
        @scenario_number = 0
        @step_number = 0
        @header_red = nil
        @delayed_messages = []
        @img_id = 0
        #############################################
        @scenario_index = 0
        @scenario_exceptions = []
        @scenario_undefined = false
        @scenario_updated = false
        @feature_result = 'PASSED'
        @start_time = 0
        Cutara::TarantulaUpdater.config = YAML.load(File.open(Cutara::SUPPORT+"/tarantula.yml"))
        #############################################
      end

      def after_features(features)
        @builder << "<p><i>#{response}</i></p>"
        print_stats(features)
        @builder << '</div>'
        @builder << '</body>'
        @builder << '</html>'
      end

      def before_feature(feature)
        @exceptions = []
        @builder << '<div class="feature">'
        #############################################
        @scenario_index = 0
        @start_time = Time.now.to_i
        #############################################
      end

      def feature_name(keyword, name)
        lines = name.split(/\r?\n/)
        return if lines.empty?
        @builder.h2 do |h2|
          @builder.span(keyword + ': ' + lines[0], :class => 'val')
        end
        @builder.p(:class => 'narrative') do
          lines[1..-1].each do |line|
            @builder.text!(line.strip)
            @builder.br
          end
        end
        #############################################
        @feature_name = name.split("\n").first
        #############################################
      end

      def scenario_name(keyword, name, file_colon_line, source_indent)
        @builder.span(:class => 'scenario_file') do
          @builder << file_colon_line
        end
        @listing_background = false
        @builder.h3(:id => "scenario_#{@scenario_number}") do
          @builder.span(keyword + ':', :class => 'keyword')
          @builder.text!(' ')
          @builder.span(name, :class => 'val')
        end
        #############################################
        @scenario_index += 1 unless @in_background
        @scenario_exceptions = []
        @scenario_undefined = false
        #############################################
      end

      def before_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
        @step_match = step_match
        @hide_this_step = false
        if exception
          if @exceptions.include?(exception)
            @hide_this_step = true
            return
          end
          @exceptions << exception
          #############################################
          @scenario_exceptions << exception
          #############################################
        end
        if status == :undefined
          #############################################
          @scenario_undefined = true
          #############################################
        end
        if status != :failed && @in_background ^ background
          @hide_this_step = true
          return
        end
        @status = status
        return if @hide_this_step
        set_scenario_color(status)
        @builder << "<li id='#{@step_id}' class='step #{status}'>"
      end

      def after_table_row(table_row)
        return if @hide_this_step
        print_table_row_messages
        @builder << '</tr>'
        if table_row.exception
          @builder.tr do
            @builder.td(:colspan => @col_index.to_s, :class => 'failed') do
              @builder.pre do |pre|
                pre << h(format_exception(table_row.exception))
              end
            end
          end
          if table_row.exception.is_a? ::Cucumber::Pending
            set_scenario_color_pending
          else
            set_scenario_color_failed
          end
        end
        if table_row.exception && !@exceptions.include?(table_row.exception)
          #############################################
          @scenario_updated = true
          message = table_row.exception.inspect.force_encoding("utf-8")
          if @in_background
            message += " !INSIDE BACKGROUND!"
          end
          response = Cutara::TarantulaUpdater.update_testcase_step(ENV["project"], ENV["execution"], @feature_name, @scenario_index, "FAILED", message)
          response += Cutara::TarantulaUpdater.update_testcase_results(ENV["project"], ENV["execution"], @feature_name, Time.now.to_i - @start_time, @feature_result)
          @feature_result = "FAILED"
          @builder << "<p><i>#{response}</i></p>"
          #############################################
        end
        if @outline_row
          @outline_row += 1
        end
        @step_number += 1
        move_progress
      end

      def after_steps(steps)
        @builder << '</ol>'
        #############################################
        result = "PASSED"
        message = ''
        position = @scenario_index
        if not @scenario_exceptions.empty?
          result = "FAILED"
          @feature_result = "FAILED"
          message = @scenario_exceptions.inspect.force_encoding("utf-8")
          @scenario_updated = true
        elsif @scenario_undefined
          result = "NOT_IMPL"
          @feature_result = "NOT_IMPL"
          message = "Undefined cucumber sentence found"
          @scenario_updated = true
        end
        if @in_background
          message += " !INSIDE BACKGROUND!"
          position = 1
        end
        response = 'Tarantula response undefined'
        begin
          response = Cutara::TarantulaUpdater.update_testcase_step(ENV["project"], ENV["execution"], @feature_name, position, result, message)
          response += Cutara::TarantulaUpdater.update_testcase_results(ENV["project"], ENV["execution"], @feature_name, Time.now.to_i - @start_time, @feature_result)
        rescue Exception => e
          response += Cutara::TarantulaUpdater.update_testcase_results(ENV["project"], ENV["execution"], @feature_name, Time.now.to_i - @start_time, @feature_result)
          response = e.message
        end
        @builder << "<p><i>#{response}</i></p>"
        #############################################
      end
    end
  end
end
