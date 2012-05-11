//
// Source du module minimal qui permet de s'initier à la programmation
//
import java.awt.*;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.io.Reader;
import java.io.StringReader;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.util.Locale;
import java.util.Scanner;
import java.util.regex.Pattern;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Line2D;
import java.awt.geom.Path2D;
import java.awt.geom.Rectangle2D;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CopyOnWriteArrayList;
import javax.swing.JComponent;
import javax.swing.JFrame;
import javax.swing.plaf.ComponentUI;

class Isn {
    private static class IsnUI extends ComponentUI {
	static final IsnUI INSTANCE = new IsnUI();
	@Override
	    public void paint(Graphics g, JComponent c) {
	    ConcurrentLinkedQueue<Entry> items = ((JIsn)c).items;
	    Graphics2D gg = (Graphics2D)g.create();
	    try {
		for(Entry entry:items)
		    entry.draw(gg);
	    }
	    finally {
		gg.dispose();
	    }
	}
    }
    private static class Entry {
	private final Shape shape;
	private final Color foreground,background;
	Entry(Shape shape, Color foreground, Color background) {
	    this.shape = shape;
	    this.foreground = foreground;
	    this.background = background;
	}
	void draw(Graphics2D gg) {
	    if (background!=null) {
		gg.setColor(background);
		gg.fill(shape);
	    }
	    if (foreground!=null) {
		gg.setColor(foreground);
		gg.draw(shape);
	    }
	}
    }
    private static class JIsn extends JComponent {
	ConcurrentLinkedQueue<Entry> items = new ConcurrentLinkedQueue<Entry>();
	JIsn(int width, int height) {
	    setUI(IsnUI.INSTANCE);
	    setPreferredSize(new Dimension(width,height));
	}
	public void add(Shape shape, Color foreground, Color background) {
	    items.add(new Entry(shape,foreground,background));
	    repaint();
	}
	public void clear() {
	    items.clear();
	    repaint();
	}
    }
    static JIsn component = null;
    public static void initDrawing (String s, int x, int y, int w, int h) {
	component = new JIsn(w,h);
	component.setOpaque(true);
	component.setBackground(Color.WHITE);
	JFrame frame = new JFrame(s);
	frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
	frame.add(component);
	frame.setLocation(x,y);
	frame.pack();
	frame.setVisible(true);
    }
    public static void drawLine(double x1,double y1,double x2, double y2) {
	component.add(new Line2D.Double(x1, y1, x2, y2),Color.BLACK,Color.WHITE);
    }
    public static void drawPixel(double x,double y,int c) {
	component.add(new Rectangle2D.Double(x,y,x+1,y+1), new Color (c,c,c),Color.WHITE);
    }
    public static void drawCircle(double cx,double cy,double r) {
	component.add(new Ellipse2D.Double(cx-r,cy-r,2*r,2*r),Color.BLACK,null);
    }
    public static void paintCircle(double cx,double cy,double r) {
	component.add(new Ellipse2D.Double(cx-r,cy-r,2*r,2*r),Color.BLACK,Color.BLACK);
    }
    public static void eraseCircle(double cx,double cy,double r) {
	component.add(new Ellipse2D.Double(cx-r,cy-r,2*r,2*r),Color.WHITE,Color.WHITE);
    }
    private static final Object readMonitor = new Object();
    private static volatile Scanner scanner
	= scanner(new InputStreamReader(System.in));
    private static Scanner scanner(Reader in) {
	Scanner scanner = new Scanner(in);
	scanner.useLocale(Locale.US);
	return scanner;
    }
    private static final Object writeMonitor = new Object();
    private static volatile PrintStream output = System.out;
    public static int readInt() {
	synchronized (readMonitor) {return scanner.nextInt();}
    }
    public static char[] readWordAsCharArray() {
	return readWord().toCharArray();
    }
    public static String readWord() {
	synchronized (readMonitor) {
	    return scanner.next();
	}
    }
    public static double readDouble() {
	synchronized (readMonitor) {
	    return scanner.nextDouble();
	}
    }
    private static final Pattern DOT = Pattern.compile(".",Pattern.DOTALL);
    public static char readChar() {
	synchronized (readMonitor) {
	    return scanner.findWithinHorizon(DOT,1).charAt(0);}
    }
}