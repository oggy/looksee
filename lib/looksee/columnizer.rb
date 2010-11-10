module Looksee
  module Columnizer
    class << self
      #
      # Arrange the given strings in columns, restricted to the given
      # width.  Smart enough to ignore content in terminal control
      # sequences.
      #
      def columnize(strings, width)
        return '' if strings.empty?

        num_columns = 1
        layout = [strings]
        loop do
          break if layout.first.length <= 1
          next_layout = layout_in_columns(strings, num_columns + 1)
          break if layout_width(next_layout) > width
          layout = next_layout
          num_columns += 1
        end

        pad_strings(layout)
        rectangularize_layout(layout)
        layout.transpose.map do |row|
          '  ' + row.compact.join('  ')
        end.join("\n") << "\n"
      end

      private  # -----------------------------------------------------

      def layout_in_columns(strings, num_columns)
        strings_per_column = (strings.length / num_columns.to_f).ceil
        (0...num_columns).map{|i| strings[i*strings_per_column...(i+1)*strings_per_column] || []}
      end

      def layout_width(layout)
        widths = layout_column_widths(layout)
        widths.inject(0){|sum, w| sum + w} + 2*layout.length
      end

      def layout_column_widths(layout)
        layout.map do |column|
          column.map{|string| display_width(string)}.max || 0
        end
      end

      def display_width(string)
        # remove terminal control sequences
        string.gsub(/\e\[.*?m/, '').length
      end

      def pad_strings(layout)
        widths = layout_column_widths(layout)
        layout.each_with_index do |column, i|
          column_width = widths[i]
          column.each do |string|
            padding = column_width - display_width(string)
            string << ' '*padding
          end
        end
      end

      def rectangularize_layout(layout)
        return if layout.length == 1
        height = layout[0].length
        layout[1..-1].each do |column|
          column.length == height or
            column[height - 1] = nil
        end
      end
    end
  end
end
