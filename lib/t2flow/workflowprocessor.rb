# Copyright (c) 2008 University of Manchester and the University of Southampton.

require 't2flow/model'
require 't2flow/parser'
require 't2flow/dot'
require 'libxml'
require 'rdf'
#require 'rdf/n3'
require 'rdf/turtle'
require 'tempfile'
require 'stringio'
require 'workflow_parser/workflow_processor'


module T2Flow
  GEM_ROOT = File.expand_path(File.join(__FILE__, "..", "..", ".."))
  SCUFL2_WFDESC_JAR = File.expand_path(File.join(GEM_ROOT, "bin", "scufl2-wfdesc-0.3.7-standalone.jar"))

  class WorkflowProcessor < WorkflowParser::WorkflowProcessor
    # Register Taverna 2 MIME Types
    # TODO: Is this possible without a dependency on actionpack?
    ##require 'action_controller/mime_type'
    ##Mime::Type.register "application/vnd.taverna.t2flow+xml", :t2flow

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.

    # MUST be unique across all processors
    def self.display_name
      "Taverna 2"
    end

    def self.display_data_format
      "T2FLOW"
    end

    def self.mime_type
      "application/vnd.taverna.t2flow+xml"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "t2flow" ]
    end

    def self.can_determine_type_from_file?
      true
    end

    def self.recognised?(file)
      begin
        file.rewind
        t2flow_model = T2Flow::Parser.new.parse(file.read)
        file.rewind
        return !t2flow_model.nil?
      rescue
        return false
      end
    end

    def self.can_infer_metadata?
      true
    end

    def self.can_infer_title?
      true
    end

    def self.can_infer_description?
      true
    end

    def self.can_generate_preview_image?
      true
    end

    def self.can_generate_preview_svg?
      true
    end

    # End Class Methods


    # Begin Object Initializer

    def initialize(workflow_definition)
      #super(workflow_definition)
      @workflow_definition = workflow_definition
      @t2flow_model = T2Flow::Parser.new.parse(workflow_definition)
    end

    # End Object Initializer


    # Begin Instance Methods

    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.

    # *** NEW ***
    def get_name
      return nil if @t2flow_model.nil?
      if @t2flow_model.annotations.name.empty? || @t2flow_model.annotations.name=~/^(workflow|dataflow)\d*$/i
        if @t2flow_model.annotations.titles.nil? || @t2flow_model.annotations.titles.empty?
          return "[untitled]"
        else
          @t2flow_model.annotations.titles[0]
        end
      else
        @t2flow_model.annotations.name
      end
    end

    def get_title
      titles = self.get_titles
      if titles
        return titles[0]
      else
        return self.get_name
      end
    end

    # *** NEW ***
    def get_titles
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.titles
    end

    def get_description
      descriptions = self.get_descriptions
      if descriptions
        desc = ""
        descriptions.each { |x|
          desc << x
          desc << "<hr/>" unless x==descriptions.last
          }
        return desc
      else
        return nil
      end
    end

    # *** NEW ***
    def get_descriptions
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.descriptions
    end

    # *** NEW ***
    def get_authors
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.authors
    end

    def get_preview_image
      return nil if @t2flow_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = self.get_name
      filename = title.gsub(/[^\w\.\-]/,'_').downcase

      i = Tempfile.new("image")
      T2Flow::Dot.new.write_dot(i, @t2flow_model)
      i.close(false)

      img = StringIO.new(`dot -Tpng #{i.path}`)
      #img.extend FileUpload
      #img.original_filename = "#{filename}.png"
      img.content_type = "image/png"

      img
    end

    def get_preview_svg
      return nil if @t2flow_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = self.get_name
      filename = title.gsub(/[^\w\.\-]/,'_').downcase

      i = Tempfile.new("image")
      T2Flow::Dot.new.write_dot(i, @t2flow_model)
      i.close(false)

      svg = StringIO.new(`dot -Tsvg #{i.path}`)
      #svg.extend FileUpload
      #svg.original_filename = "#{filename}.svg"
      svg.content_type = "image/svg+xml"

      svg
    end

    def get_workflow_model_object
      @t2flow_model
    end

    def get_workflow_model_input_ports
      return (@t2flow_model.nil? ? nil : @t2flow_model.sources)
    end

    def get_search_terms
      def get_scufl_metadata(model)
        words = StringIO.new

        model.annotations.descriptions.each { |desc|
          words << " #{desc}"
        } if model.annotations.descriptions

        model.sources.each do |source|
          words << " #{source.name}" if source.name
          source.descriptions.each { |desc|
            words << " #{desc}"
          } if source.descriptions
        end

        model.sinks.each do |sink|
          words << " #{sink.name}" if sink.name
          sink.descriptions.each { |desc|
            words << " #{desc}"
          } if sink.descriptions
        end

        model.processors.each do |processor|
          words << " #{processor.name}" if processor.name
          words << " #{processor.description}" if processor.description
        end

        words.rewind
        words.read
      end

      return "" if @t2flow_model.nil?
      return get_scufl_metadata(@t2flow_model)
    end

    def build(name, text = nil, &blk)
      node = XML::Node.new(name)
      node << text if text
      yield(node) if blk
      node
    end

    def build_semantic_annotation_element(object)
      build('semantic_annotation') do |semantic_annotation_element|
        if object.semantic_annotation
          semantic_annotation_element << build('type', object.semantic_annotation.type)
          semantic_annotation_element << build('content', object.semantic_annotation.content)
        end
      end
    end

    def get_components_aux(base_model, model, tag)

      build(tag) do |components|

        components << build('dataflows') do |dataflows_element|

          model.dataflows.each do |dataflow|

            dataflows_element << build('dataflow') do |dataflow_element|

              dataflow_element['id']   = dataflow.dataflow_id
              dataflow_element['role'] = dataflow.role

              dataflow_element << build('sources') do |sources_element|

                dataflow.sources.each do |source|

                  sources_element << build('source') do |source_element|

                    source_element << build('name', source.name) if source.name

                    source_element << build('descriptions') do |source_descriptions_element|

                      if source.descriptions
                        source.descriptions.each do |source_description|

                          source_descriptions_element << build('description', source_description)
                        end
                      end
                    end

                    source_element << build('examples') do |source_examples_element|

                      if source.example_values
                        source.example_values.each do |source_example_value|

                          source_examples_element << build('example', source_example_value)
                        end
                      end
                    end

                    source_element << build_semantic_annotation_element(source) if source.semantic_annotation
                  end
                end
              end

              dataflow_element << build('sinks') do |sinks_element|

                dataflow.sinks.each do |sink|

                  sinks_element << build('sink') do |sink_element|

                    sink_element << build('name', sink.name) if sink.name

                    sink_element << build('descriptions') do |sink_descriptions_element|

                      if sink.descriptions
                        sink.descriptions.each do |sink_description|
                          sink_descriptions_element << build('description', sink_description)
                        end
                      end
                    end

                    sink_element << build('examples') do |sink_examples_element|

                      if sink.example_values
                        sink.example_values.each do |sink_example_value|

                          sink_examples_element << build('example', sink_example_value)
                        end
                      end
                    end
                    sink_element << build_semantic_annotation_element(sink) if sink.semantic_annotation
                  end
                end
              end

              dataflow_element << build('processors') do |processors_element|

                dataflow.processors.each do |processor|

                  processors_element << build('processor') do |processor_element|

                    processor_element << build('name',                   processor.name)                   if processor.name
                    processor_element << build('description',            processor.description)            if processor.description
                    processor_element << build('type',                   processor.type)                   if processor.type
                    processor_element << build('dataflow-id',            processor.dataflow_id)            if processor.dataflow_id

                    processor_element << build('script',                 processor.script)                 if processor.script
                    processor_element << build('wsdl',                   processor.wsdl)                   if processor.wsdl
                    processor_element << build('wsdl-operation',         processor.wsdl_operation)         if processor.wsdl_operation
                    processor_element << build('endpoint',               processor.endpoint)               if processor.endpoint
                    processor_element << build('biomoby-authority-name', processor.biomoby_authority_name) if processor.biomoby_authority_name
                    processor_element << build('biomoby-service-name',   processor.biomoby_service_name)   if processor.biomoby_service_name
                    processor_element << build('biomoby-category',       processor.biomoby_category)       if processor.biomoby_category
                    processor_element << build('value',                  processor.value)                  if processor.value
                    processor_element << build_semantic_annotation_element(processor)                      if processor.semantic_annotation

                    if processor.dataflow_id
                      nested_dataflow = base_model.dataflow(processor.dataflow_id)
                    end
                  end
                end
              end

              dataflow_element << build('datalinks') do |links_element|

                dataflow.datalinks.each do |datalink|

                  sink_bits   = datalink.sink.split(':')
                  source_bits = datalink.source.split(':')

                  links_element << build('datalink') do |datalink_element|

                    datalink_element << build('sink') do |sink_element|
                      sink_element << build('node', sink_bits[0]) if sink_bits[0]
                      sink_element << build('port', sink_bits[1]) if sink_bits[1]
                    end

                    datalink_element << build('source') do |source_element|
                      source_element << build('node', source_bits[0]) if source_bits[0]
                      source_element << build('port', source_bits[1]) if source_bits[1]
                    end
                  end
                end
              end

              dataflow_element << build_semantic_annotation_element(dataflow.annotations) if dataflow.annotations.semantic_annotation
            end
          end
        end
      end
    end

    def get_components
      get_components_aux(@t2flow_model, @t2flow_model, 'components')
    end

    def extract_metadata(workflow)

      @t2flow_model.all_processors.each do |processor|
        workflow_processor = WorkflowProcessor.create(:workflow => workflow,
            :name           => processor.name,
            :wsdl           => processor.wsdl,
            :wsdl_operation => processor.wsdl)
      end

      @t2flow_model.sources.each do |source|
        port = WorkflowPort.create(:workflow => workflow,
                            :port_type => "input",
                            :name => source.name)
      end

      @t2flow_model.sinks.each do |sink|
        port = WorkflowPort.create(:workflow => workflow,
                            :port_type => "output",
                            :name => sink.name)
      end

    end

    def to_json
      unless @t2flow_model.nil?
        @t2flow_model.to_json
      end
    end

    def self.extract_rdf_structure(workflow_str)
      rdf = ''
      if ! File.exist? SCUFL2_WFDESC_JAR
        raise "Can't find #{SCUFL2_WFDESC_JAR}"
      end
      IO.popen("java -jar #{SCUFL2_WFDESC_JAR}", 'r+') do |converter|
        converter.puts(workflow_str)
        converter.close_write
        rdf = converter.read
      end

      raise "Error generating wfdesc" if rdf.empty?

      rdf
    end

    # End Instance Methods
  end
end
