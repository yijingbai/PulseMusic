import UIKit
import WatchConnectivity
import AVFoundation


class ViewController: UIViewController, APChartViewDelegate, WCSessionDelegate , UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate {
    @IBOutlet weak var HeartRateLabel: UILabel!
    @IBOutlet var chart: APChartView!
    @IBOutlet var lblPoint: UILabel!
    @IBOutlet weak var headerView: UIView!
    
    
    var audioPlayer = AVAudioPlayer()
    var currentAudio = "";
    var currentAudioPath:NSURL!
    var audioList:NSArray!
    var currentAudioIndex = 0
    var timer:NSTimer!
    var audioLength = 0.0
    var toggle = true
    var effectToggle = true
    var totalLengthOfAudio = ""
    var finalImage:UIImage!
    var isTableViewOnscreen = false
    var rateMulti:Float = 1.0
    var currentRangeLow = 0
    var currentRangeHigh = 100
    
    @IBOutlet var songNo : UILabel!
    @IBOutlet var lineView : UIView!
    @IBOutlet var songNameLabel : UILabel!
    @IBOutlet var songNameLabelPlaceHolder : UILabel!
    @IBOutlet var progressTimerLabel : UILabel!
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    @IBOutlet var previousButton : UIButton!
    @IBOutlet var playButton : UIButton!
    @IBOutlet var nextButton : UIButton!
    @IBOutlet var listButton : UIButton!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var blurImageView : UIImageView!
    @IBOutlet var enhancer : UIView!
    @IBOutlet var tableViewContainer : UIView!
    
    
    @IBAction func rateMulti(sender: UISlider) {
        NSLog("multiValue is " + String(sender.value))
        rateMulti = sender.value
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {
        var songNameDict = NSDictionary();
        songNameDict = audioList.objectAtIndex(indexPath.row) as! NSDictionary
        var songName = songNameDict.valueForKey("songName") as! String
        
        var albumNameDict = NSDictionary();
        albumNameDict = audioList.objectAtIndex(indexPath.row) as! NSDictionary
        var albumName = albumNameDict.valueForKey("albumName") as! String
        
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont(name: "Didot", size: 25.0)
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.text = songName
        
        cell.detailTextLabel?.font = UIFont(name: "Didot", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.text = albumName
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54.0
    }
    
    func tableView(tableView: UITableView,willDisplayCell cell: UITableViewCell!,forRowAtIndexPath indexPath: NSIndexPath!){
        tableView.backgroundColor = UIColor.clearColor()
        
        let backgroundView = UIView(frame: CGRectZero)
        backgroundView.backgroundColor = UIColor.clearColor()
        cell.backgroundView = backgroundView
        cell.backgroundColor = UIColor.clearColor()
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        animateTableViewToOffScreen()
        currentAudioIndex = indexPath.row
        prepareAudio()
        playAudio()
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, forState: UIControlState.Normal))" : "\(listButton.setImage(removeList , forState: UIControlState.Normal))"
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
        
    }
    
    
    func captureScreen(){
        self.blurImageView.hidden = true
        self.blurImageView.alpha = 0.0
        
        UIGraphicsBeginImageContext(self.view.bounds.size);
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
    }

    
    
    func applyBlurEffect(image: UIImage){
        var imageToBlur = CIImage(image: image)
        var blurfilter = CIFilter(name: "CIGaussianBlur")
        blurfilter!.setValue(imageToBlur, forKey: "inputImage")
        var resultImage = blurfilter!.valueForKey("outputImage") as! CIImage
        var blurredImage = UIImage(CIImage: resultImage)
        self.blurImageView.image = blurredImage
        self.blurImageView.hidden = false
        self.blurImageView.alpha = 1.0
        
    }
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        
        if isTableViewOnscreen{
            return true
        }else{
            return false
        }
    }
    
    func setCurrentAudioPath(){
        currentAudio = readSongNameFromPlist(currentAudioIndex)
        currentAudioPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(currentAudio, ofType: "mp3")!)
        print("\(currentAudioPath)")
    }
    
    
    func saveCurrentTrackNumber(){
        NSUserDefaults.standardUserDefaults().setObject(currentAudioIndex, forKey:"currentAudioIndex")
        NSUserDefaults.standardUserDefaults().synchronize()
        
    }
    
    func retrieveSavedTrackNumber(){
        
        if let currentAudioIndex_ = NSUserDefaults.standardUserDefaults().objectForKey("currentAudioIndex") as? Int{
            currentAudioIndex = currentAudioIndex_
        }else{
            currentAudioIndex = 0
        }
        
    }
    
    func prepareAudio(){
        setCurrentAudioPath()
        do {
            //keep alive audio at background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        audioPlayer = try! AVAudioPlayer(contentsOfURL: currentAudioPath)
        audioPlayer.delegate = self
        audioLength = audioPlayer.duration
        playerProgressSlider.maximumValue = CFloat(audioPlayer.duration)
        playerProgressSlider.minimumValue = 0.0
        playerProgressSlider.value = 0.0
        audioPlayer.prepareToPlay()
        showTotalSurahLength()
        updateLabels()
        progressTimerLabel.text = "00:00:00"
        
        
    }
    
    func  playAudio(){
        audioPlayer.play()
        startTimer()
        updateLabels()
        saveCurrentTrackNumber()
    }
    
    func playNextAudio(){
        currentAudioIndex++
        if currentAudioIndex>audioList.count-1{
            currentAudioIndex--
            
            return
        }
        if audioPlayer.playing{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func playPreviousAudio(){
        currentAudioIndex--
        if currentAudioIndex<0{
            currentAudioIndex++
            return
        }
        if audioPlayer.playing{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func stopAudiplayer(){
        audioPlayer.stop();
        
    }
    
    func pauseAudioPlayer(){
        audioPlayer.pause()
        
    }
    
    func startTimer(){
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update:"), userInfo: nil,repeats: true)
            timer.fire()
        }
    }
    
    func stopTimer(){
        timer.invalidate()
        
    }
    
    
    func update(timer: NSTimer){
        if !audioPlayer.playing{
            return
        }
        
        let hour_   = abs(Int(audioPlayer.currentTime)/3600)
        let minute_ = abs(Int((audioPlayer.currentTime/60) % 60))
        let second_ = abs(Int(audioPlayer.currentTime  % 60))
        
        let hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        
        progressTimerLabel.text  = "\(hour):\(minute):\(second)"
        playerProgressSlider.value = CFloat(audioPlayer.currentTime)
        
    }
    
    
    
    
    func showTotalSurahLength(){
        calculateSurahLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }
    
    
    func calculateSurahLength(){
        let hour_ = abs(Int(audioLength/3600))
        let minute_ = abs(Int((audioLength/60) % 60))
        let second_ = abs(Int(audioLength % 60))
        
        let hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        totalLengthOfAudio = "\(hour):\(minute):\(second)"
    }
    
    
    
    func readSongNameFromPlist(indexNumber: Int) -> String {
        
        let path = NSBundle.mainBundle().pathForResource("list", ofType: "plist")
        audioList = NSArray(contentsOfFile:path!)
        
        var songNameDict = NSDictionary();
        songNameDict = audioList.objectAtIndex(indexNumber) as! NSDictionary
        var songName = songNameDict.valueForKey("songName") as! String
        return songName
    }
    
    
    
    
    
    func updateLabels(){
        updateSongNameLabel()
        updateBigSongNumber()
        
    }
    
    
    func updateSongNameLabel(){
        let songName = readSongNameFromPlist(currentAudioIndex)
        songNameLabel.text = songName
    }
    
    
    
    func updateBigSongNumber(){
        //   songNo.text = "\(currentAudioIndex+1)"
    }
    
    func animateTableViewToScreen(){
        
        
        
        UIView.animateWithDuration(0.25, delay: 0.2, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            
            self.tableViewContainer.frame = CGRectMake(
                self.tableViewContainer.frame.origin.x,
                17,
                self.tableViewContainer.frame.size.width,
                self.tableViewContainer.frame.size.height)
            
            }, completion: nil)
        
        
    }
    
    func animateTableViewToOffScreen(){
        isTableViewOnscreen = false
        setNeedsStatusBarAppearanceUpdate()
        
        animateBlurImageBack()
        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.tableViewContainer.frame = CGRectMake(
                self.tableViewContainer.frame.origin.x,568,
                self.tableViewContainer.frame.size.width,
                self.tableViewContainer.frame.size.height)
            
            }, completion: {
                (value: Bool) in
                self.enhancer.hidden = true
        })
    }
    
    
    func animateBlurImageBack(){
        UIView.animateWithDuration(0.25, delay: 0.2, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.blurImageView.alpha = 0.0
            }, completion: nil)
    }
    
    
    
    func addDropShadowToTableViewContainer(){
        self.tableViewContainer.layer.shadowColor = UIColor.blackColor().CGColor
        self.tableViewContainer.layer.shadowOffset = CGSizeMake(5.0,5.0)
        self.tableViewContainer.layer.masksToBounds = false
        self.tableViewContainer.layer.shadowRadius = 5.0
        self.tableViewContainer.layer.shadowOpacity = 1.0
    }
    
    
    
    @IBAction func play(sender : AnyObject) {
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        if audioPlayer.playing{
            pauseAudioPlayer()
            audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
            
        }else{
            playAudio()
            audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
        }
    }
    
    
    
    @IBAction func next(sender : AnyObject) {
        playNextAudio()
    }
    
    
    @IBAction func previous(sender : AnyObject) {
        playPreviousAudio()
    }
    
    
    
    
    @IBAction func changeAudioLocationSlider(sender : UISlider) {
        audioPlayer.currentTime = NSTimeInterval(sender.value)
        
    }
    
    
    @IBAction func userTapped(sender : UITapGestureRecognizer) {
        
        play(self)
    }
    
    @IBAction func userSwipeLeft(sender : UISwipeGestureRecognizer) {
        next(self)
    }
    
    @IBAction func userSwipeRight(sender : UISwipeGestureRecognizer) {
        previous(self)
    }
    
    @IBAction func userSwipeUp(sender : UISwipeGestureRecognizer) {
        presentListTableView(self)
    }
    
    
    
    @IBAction func presentListTableView(sender : AnyObject) {
        if effectToggle{
            isTableViewOnscreen = true
            setNeedsStatusBarAppearanceUpdate()
            captureScreen()
            self.applyBlurEffect(self.finalImage)
            self.enhancer.hidden = false
            addDropShadowToTableViewContainer()
            self.animateTableViewToScreen()
            
        }else{
            self.animateTableViewToOffScreen()
            
        }
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, forState: UIControlState.Normal))" : "\(listButton.setImage(removeList , forState: UIControlState.Normal))"
    }
    
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool){
        if flag{
            currentAudioIndex++
            if currentAudioIndex>audioList.count-1{
                currentAudioIndex--
                return
            }
            prepareAudio()
            playAudio()
        }
    }

    
    

    
    var graphtimer: NSTimer?
    var seconds = 0
    var linePoints: [(Int, Int)] = []

    var isDrawing: Bool = false
    var lineColor: UIColor = UIColor.whiteColor()
    
    
    @IBAction func createLine(){
        chart.collectionLines = []
        let line = APChartLine(chartView: chart, title: "prova", lineWidth: 2.0, lineColor: lineColor)
        
        for item in linePoints {
            line.addPoint(CGPoint(x:CGFloat(item.0), y: CGFloat(item.1)))
        }
       
        chart.addLine(line)
        
        self.chart.addMarkerLine("targetLow", y: 100.0 )
        self.chart.addMarkerLine("targetHigh", y: 150.0 )
    }
    
    func didSelectNearDataPoint(selectedDots: [String : APChartPoint]) {
        var txt = ""
        for (title,value) in selectedDots {
            txt = "\(txt)\(title): \(value.dot)\n"
        }
    }
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if let chartV = chart {
            chartV.setNeedsDisplay()
        }
    }

    var watchSession: WCSession? {
        didSet {
            if let watchSession = watchSession {
                NSLog("Start init WCSession from Phone")
                watchSession.delegate = self
                watchSession.activateSession()
            }
        }
    }
    
    func updateGraphTimer() {
        seconds += 1
        if (isDrawing) {
            createLine()
            chart.setNeedsDisplay()
        }
        NSLog(String(seconds) + "seconds")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named:"back.png")!)
        NSLog("application ran")
        if WCSession.isSupported() {
            watchSession = WCSession.defaultSession()
        }
        
        graphtimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "updateGraphTimer", userInfo: nil, repeats: true)

        chart.delegate = self
        
        
        enhancer.hidden = true
        //this sets last listened trach number as current
        retrieveSavedTrackNumber()
        prepareAudio()
        updateLabels()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let rate = message["rate"] {
            
            let nrate = String(rate) as NSString
            let heartRate = Int(round(nrate.floatValue * rateMulti))
            NSLog("HeartRate is " + String(heartRate))
            if (isDrawing) {

                if (linePoints.count > 50) {
                    linePoints.removeAll()
                    linePoints.append((seconds, heartRate))
                }
                
                if heartRate > currentRangeHigh {
                    
                    if heartRate < 150 {
                        currentRangeLow = 100
                        currentRangeHigh = 150
                    } else if heartRate > 150 {
                        currentRangeLow = 150
                        currentRangeHigh = 200
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.next(self)
//                        self.playAudio()
                    })
                }
                
                if heartRate < currentRangeLow {
                    if heartRate < 150 {
                        currentRangeLow = 100
                        currentRangeHigh = 150
                    } else if heartRate < 100 {
                        currentRangeLow = 0
                        currentRangeHigh = 100
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.previous(self)
//                        self.playAudio()
                    })
                }
                
                if heartRate < 100 {
                    previous(self)
                    lineColor = UIColor.whiteColor()
                    chart.backgroundColor = UIColor.clearColor()
                } else if heartRate < 150 {
                    next(self)
                    lineColor = UIColor.whiteColor()
                    chart.backgroundColor = UIColor.orangeColor()
                } else if heartRate > 150 {
                    next(self)
                    lineColor = UIColor.whiteColor()
                    chart.backgroundColor = UIColor.redColor()
                }

                linePoints.append((seconds, heartRate))

            } else {
                isDrawing = true
                seconds = 0
                linePoints.append((seconds, heartRate))
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.play(self)
                })
            }
            
            NSLog(linePoints.debugDescription)
            
            
        }
        
    }

}



