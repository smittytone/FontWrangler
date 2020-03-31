
//  Created by Tony Smith on 31/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class FontWranglerFontListTableViewCell: UITableViewCell {


    @IBOutlet weak var downloadProgressView: UIActivityIndicatorView!
    @IBOutlet weak var fontNameLabel: UILabel!


    override func awakeFromNib() {

        super.awakeFromNib()
    }


    override func setSelected(_ selected: Bool, animated: Bool) {

        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
