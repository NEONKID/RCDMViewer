package xyz.neonkid.rcdmviewer;

import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.FileReader;
import java.io.IOException;
import java.sql.DatabaseMetaData;

/**
 * Created by neonkid on 6/23/19
 */

public class Main {
    public static void main(String[] args) throws IOException, ParseException {
        JSONParser parser = new JSONParser();
        Object obj = parser.parse(new FileReader("/home/neonkid/cohort.json"));
        Object op = parser.parse(new FileReader("/home/neonkid/options.json"));

        String options = ((JSONObject) op).toJSONString();
        String expression = ((JSONObject) obj).toJSONString();

        // System.out.println(options);
        // System.out.println(expression);

        CohortQuery query = new CohortQuery();
        System.out.println(query.generateSql(options, expression));
    }
}
