# frozen_string_literal: true

module PGExaminer
  class Base
    def diffable_attrs
      {}
    end

    def diffable_lists
      []
    end

    def diffable_methods
      []
    end

    def diff(other)
      raise "Can't diff a #{self.class} and a #{other.class}" unless self.class == other.class

      r = {}

      diffable_attrs.each do |attr, description|
        this = @row.fetch(attr)
        that = other.row.fetch(attr)

        unless this == that
          r[description] = {this => that}
        end
      end

      diffable_methods.each do |attr, description|
        this = send(attr)
        that = other.send(attr)

        unless this == that
          r[description] = {this => that}
        end
      end

      diffable_lists.each do |attr, description|
        these = send(attr)
        those = other.send(attr)
        these_names = these.map(&:name)
        those_names = those.map(&:name)

        if these_names == those_names
          result = these.zip(those).each_with_object({}) do |(this, that), hash|
            if (result = this.diff(that)).any?
              hash[this.name] = result
            end
          end

          if result.any?
            r[description] = result
          end
        else
          added   = those_names - these_names
          removed = these_names - those_names

          h = {}
          h['added']   = added   if added.any?
          h['removed'] = removed if removed.any?
          r[description] = h
        end
      end

      r
    end

    def ==(other)
      self.class == other.class && diff(other) == {}
    end
  end
end
