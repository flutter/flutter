package org.dartlang.vm.service.element;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Superclass for all observatory elements.
 */
public class Element {
  protected final JsonObject json;

  public Element(JsonObject json) {
    this.json = json;
  }

  /**
   * A utility method to handle null values and JsonNull values.
   */
  String getAsString(String name) {
    final JsonElement element = json.get(name);
    return (element == null || element == JsonNull.INSTANCE) ? null : element.getAsString();
  }

  /**
   * A utility method to handle null values and JsonNull values.
   */
  int getAsInt(String name) {
    final JsonElement element = json.get(name);
    return (element == null || element == JsonNull.INSTANCE) ? -1 : element.getAsInt();
  }

  /**
   * A utility method to handle null values and JsonNull values.
   */
  boolean getAsBoolean(String name) {
    final JsonElement element = json.get(name);
    return (element == null || element == JsonNull.INSTANCE) ? false : element.getAsBoolean();
  }

  /**
   * Return the underlying JSON backing this element.
   */
  public JsonObject getJson() {
    return json;
  }

  /**
   * Return a specific JSON member as a list of integers.
   */
  List<Integer> getListInt(String memberName) {
    return jsonArrayToListInt(json.getAsJsonArray(memberName));
  }

  /**
   * Return a specific JSON member as a list of strings.
   */
  List<String> getListString(String memberName) {
    return jsonArrayToListString(json.getAsJsonArray(memberName));
  }

  /**
   * Return a specific JSON member as a list of list of integers.
   */
  List<List<Integer>> getListListInt(String memberName) {
    JsonArray array = json.getAsJsonArray(memberName);
    if (array == null) {
      return null;
    }
    int size = array.size();
    List<List<Integer>> result = new ArrayList<>();
    for (int index = 0; index < size; ++index) {
      result.add(jsonArrayToListInt(array.get(index).getAsJsonArray()));
    }
    return result;
  }

  private List<Integer> jsonArrayToListInt(JsonArray array) {
    int size = array.size();
    List<Integer> result = new ArrayList<>();
    for (int index = 0; index < size; ++index) {
      result.add(array.get(index).getAsInt());
    }
    return result;
  }

  private List<String> jsonArrayToListString(JsonArray array) {
    int size = array.size();
    List<String> result = new ArrayList<>();
    for (int index = 0; index < size; ++index) {
      final JsonElement elem = array.get(index);
      result.add(elem == JsonNull.INSTANCE ? null : elem.getAsString());
    }
    return result;
  }
}
