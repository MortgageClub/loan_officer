class SortTest
  def self.selection_sort(array)
    arr = array
    length = array.length

    (0...length).each do |i|
      min_i = i 
      
      (i + 1...length).each do |j|
        min_i = j if arr[min_i] > arr[j]
      end

      if arr[min_i] < arr[i]
        tmp = arr[i]
        arr[i] = arr[min_i]
        arr[min_i] = tmp
      end
    end

    arr
  end

  def self.insertion_sort(array)
    arr = array
    length = array.length

    (0...length).each do |i|
      saved = arr[i]

      j = i

      while j > 0
        next if saved > arr[j - 1]

        arr[j] = arr[j-1]

        j -= 1
      end
      arr[j] = saved
    end

    arr
  end

  def self.binary_search(key)
    left = 0
    right = length - 1

    while left <= right
      mid = (left + right) / 2
      
      return mid if array[mid] == key 

      if key < array[mid]
        right = mid - 1
      else
        left = mid + 1
      end
    end

    return -1
  end

  def self.merge_sort(arr)
    return arr if arr.length <= 1

    mid = arr.length / 2

    left = self.merge_sort(arr[0..mid])
    right = self.merge_sort(arr[mid+1..arr.length])
    
    merge(left, right)
  end

  def self.merge(left, right)
    sorted = []

    until left.empty? || right.empty?
      if left.first < right.first
        sorted << left.shift
      else
        sorted << right.shift
      end
    end

    sorted
  end
end

I have a very specific plan for my career 5 years later and the position that I desire and work for.
In the first following 2 years, my target is to become a Senior Developer. This is  definitely a stepping stone for my current statement. 
I will learn and understand what exactly I need to make the highest effort for it.

Then, in 2022, I would be a software engineer, sooner or later. To climb to that position, I need to continue enrich the related knowledge and experience. 
For example: I will and should want to understand all the little pieces of the product—not just know they exist, but understand their implementation, limitations, the technical debt, etc. associated with each part of the system.
Furthermore, learning about how it interacts with other software—software you write and complementary software, and competitor’s software.
And understand how your customers use the software, and also what they need.

And of course, Besides that goal, I will make my english perfect. Being a fluent english speaker is a extremely wonderful goal for my following years. This will support me in every aspect of my life and working life